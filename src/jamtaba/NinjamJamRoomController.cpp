#include "NinjamJamRoomController.h"
#include "MainController.h"
#include "audio/core/AudioDriver.h"
#include "ninjam/Service.h"
#include "ninjam/User.h"
#include "ninjam/Server.h"
#include "../NinjamRoomWindow.h"
#include "../audio/NinjamTrackNode.h"
#include <QMutexLocker>
#include "../audio/MetronomeTrackNode.h"

#include <QDebug>
#include <QThread>

#include "audio/samplesbufferrecorder.h"

using namespace Controller;

NinjamJamRoomController::NinjamJamRoomController(Controller::MainController* mainController)
    :mainController(mainController),
    metronomeTrackNode(new Audio::MetronomeTrackNode(":/click.wav", mainController->getAudioDriver()->getSampleRate())),
    intervalPosition(0),
    samplesInInterval(0),
    newBpi(-1), newBpm(-1),
    currentBpi(0),
    currentBpm(0),
    recorder("record.wav", mainController->getAudioDriver()->getSampleRate())
{
    running = false;
}

NinjamJamRoomController::~NinjamJamRoomController()
{
    delete metronomeTrackNode;

}

void NinjamJamRoomController::start(const Ninjam::Server& server){
    //schedule an update in internal attributes
    newBpi = server.getBpi();
    newBpm = server.getBpm();
    processScheduledChanges();

    if(!running){

        //Audio::OscillatorAudioNode* osc = new Audio::OscillatorAudioNode(440 * 2, mainController->getAudioDriver()->getSampleRate());
        //mainController->addTrack(-5, osc);
        //mainController->setTrackLevel(-5, 0.6);

        mainController->addTrack(-1, this->metronomeTrackNode);

        this->intervalPosition  = 0;
        this->running = true;

        Ninjam::Service* ninjamService = Ninjam::Service::getInstance();
        QObject::connect(ninjamService, SIGNAL(serverBpmChanged(short)), this, SLOT(ninjamServerBpmChanged(short)));
        QObject::connect(ninjamService, SIGNAL(serverBpiChanged(short,short)), this, SLOT(ninjamServerBpiChanged(short,short)));
        QObject::connect(ninjamService, SIGNAL(audioIntervalCompleted(Ninjam::User,int,QByteArray)), this, SLOT(ninjamAudiointervalCompleted(Ninjam::User,int,QByteArray)));
        QObject::connect(ninjamService, SIGNAL(disconnectedFromServer(Ninjam::Server)), this, SLOT(ninjamDisconnectedFromServer(Ninjam::Server)));

        QObject::connect(ninjamService, SIGNAL(userChannelCreated(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelCreated(Ninjam::User, Ninjam::UserChannel)));
        QObject::connect(ninjamService, SIGNAL(userChannelRemoved(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelRemoved(Ninjam::User, Ninjam::UserChannel)));
        QObject::connect(ninjamService, SIGNAL(userChannelUpdated(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelUpdated(Ninjam::User, Ninjam::UserChannel)));
        QObject::connect(ninjamService, SIGNAL(audioIntervalDownloading(Ninjam::User,int,int)), this, SLOT(ninjamAudiointervalDownloading(Ninjam::User,int,int)));

        QObject::connect(ninjamService, SIGNAL(chatMessageReceived(Ninjam::User,QString)), this, SIGNAL(chatMsgReceived(Ninjam::User,QString)));

        //add server users
        QList<Ninjam::User*> users = server.getUsers();
        foreach (Ninjam::User* user, users) {
            foreach (Ninjam::UserChannel* channel, user->getChannels()) {
                addTrack(*user, *channel);
            }
        }

    }
}

void NinjamJamRoomController::sendChatMessage(QString msg){
    Ninjam::Service::getInstance()->sendChatMessageToServer(msg);
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
long NinjamJamRoomController::generateNewTrackID(){
    static long TRACK_IDS = 0;
    long newID = TRACK_IDS;
    TRACK_IDS++;
    return newID;
}

QString NinjamJamRoomController::getUniqueKey(Ninjam::UserChannel channel){
    return channel.getUserFullName() + QString::number(channel.getIndex());
}

void NinjamJamRoomController::addTrack(Ninjam::User user, Ninjam::UserChannel channel){
    if(user.isBot()){
        return;
    }
    NinjamTrackNode* trackNode = new NinjamTrackNode(generateNewTrackID());
    {
        QMutexLocker locker(&mutex);
        trackNodes.insert(getUniqueKey(channel), trackNode);
        mainController->addTrack(trackNode->getID(), trackNode);
    }
    emit channelAdded(user,  channel, trackNode->getID());
}


void NinjamJamRoomController::removeTrack(Ninjam::User user, Ninjam::UserChannel channel){
    //qDebug() << "Removendo track " << channel.getName() << " do user " << user.getName();
    QMutexLocker locker(&mutex);
    QString uniqueKey = getUniqueKey(channel);
    if(trackNodes.contains(uniqueKey)){
        NinjamTrackNode* trackNode = trackNodes[uniqueKey];
        long ID = trackNode->getID();
        trackNode->deactivate();//tracks are deactivated and deleted in next step
        //mainController->removeTrack(ID);
        emit channelRemoved(user, channel, ID);
    }
    else{
        qDebug() << " não encontrou o channel em trackNodes";

    }
}
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void NinjamJamRoomController::voteBpi(int bpi){
    Ninjam::Service::getInstance()->voteToChangeBPI(bpi);
}

void NinjamJamRoomController::voteBpm(int bpm){
    Ninjam::Service::getInstance()->voteToChangeBPM(bpm);
}
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void NinjamJamRoomController::setMetronomeBeatsPerAccent(int beatsPerAccent){
    metronomeTrackNode->setBeatsPerAccent(beatsPerAccent);
}

void NinjamJamRoomController::stop(){
    if(running){
        this->running = false;

        Ninjam::Service* ninjamService = Ninjam::Service::getInstance();
        QObject::disconnect(ninjamService, SIGNAL(serverBpmChanged(short)), this, SLOT(ninjamServerBpmChanged(short)));
        QObject::disconnect(ninjamService, SIGNAL(serverBpiChanged(short,short)), this, SLOT(ninjamServerBpiChanged(short,short)));
        QObject::disconnect(ninjamService, SIGNAL(audioIntervalCompleted(Ninjam::User,int,QByteArray)), this, SLOT(ninjamAudiointervalCompleted(Ninjam::User,int,QByteArray)));
        QObject::disconnect(ninjamService, SIGNAL(audioIntervalDownloading(Ninjam::User,int,int)), this, SLOT(ninjamAudiointervalDownloading(Ninjam::User,int,int)));
        QObject::disconnect(ninjamService, SIGNAL(userLeaveTheJam(Ninjam::User)), this, SLOT(ninjamUserLeave(Ninjam::User)));

        QObject::disconnect(ninjamService, SIGNAL(userChannelCreated(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelCreated(Ninjam::User, Ninjam::UserChannel)));
        QObject::disconnect(ninjamService, SIGNAL(userChannelRemoved(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelRemoved(Ninjam::User, Ninjam::UserChannel)));
        QObject::disconnect(ninjamService, SIGNAL(userChannelUpdated(Ninjam::User, Ninjam::UserChannel)), this, SLOT(ninjamUserChannelUpdated(Ninjam::User, Ninjam::UserChannel)));
        QObject::disconnect(ninjamService, SIGNAL(disconnectedFromServer(Ninjam::Server)), this, SLOT(ninjamDisconnectedFromServer(Ninjam::Server)));

        ninjamService->disconnectFromServer();
    }
}

void NinjamJamRoomController::deleteDeactivatedTracks(){
    QMutexLocker locker(&mutex);
    QList<QString> keys = trackNodes.keys();
    foreach (QString key, keys) {
        NinjamTrackNode* trackNode = trackNodes[key];
        if(!(trackNode->isActivated())){
            trackNodes.remove(key);
            mainController->removeTrack(trackNode->getID());
            //delete trackNode; //BUG - sometimes Jamtaba crash when trackNode is deleted
        }
    }
}


void NinjamJamRoomController::process(Audio::SamplesBuffer &in, Audio::SamplesBuffer &out){
    deleteDeactivatedTracks();

    int totalSamplesToProcess = out.getFrameLenght();
    int samplesProcessed = 0;
    static int lastBeat = 0;
    int offset = 0;
    do{
        int samplesToProcessInThisStep = std::min((int)(samplesInInterval - intervalPosition), totalSamplesToProcess - offset);
        static Audio::SamplesBuffer tempBuffer(2, samplesToProcessInThisStep);
        tempBuffer.setFrameLenght(samplesToProcessInThisStep);
        tempBuffer.zero();

        if(this->intervalPosition == 0){//starting new interval
            if(hasScheduledChanges()){
                processScheduledChanges();
            }
            QMutexLocker locker(&mutex);
            foreach (NinjamTrackNode* track, trackNodes.values()) {
                bool trackWasPlaying = track->isPlaying();
                bool trackIsPlaying = track->startNewInterval();
                if(trackWasPlaying != trackIsPlaying){
                    emit channelXmitChanged(track->getID(), trackIsPlaying);
                }
            }
        }
        metronomeTrackNode->setIntervalPosition(this->intervalPosition);

        int currentBeat = intervalPosition / getSamplesPerBeat();
        if(currentBeat != lastBeat){
            lastBeat = currentBeat;
            emit intervalBeatChanged(currentBeat);
        }
        //+++++++++++ MAIN PROCESS +++++++++++++++
        mainController->doAudioProcess(in, tempBuffer);
//        if(intervalPosition == 0){
//            tempBuffer.fadeIn(tempBuffer.getFrameLenght());
//        }
//        if(intervalPosition + samplesToProcessInThisStep >= samplesInInterval){//last interval buffer
//            tempBuffer.fadeOut(tempBuffer.getFrameLenght());
//        }
        out.add(tempBuffer, offset);
        //++++++++++++++++++++++++++++++++++++++++

        samplesProcessed += samplesToProcessInThisStep;
        offset += samplesToProcessInThisStep;
        this->intervalPosition = (this->intervalPosition + samplesToProcessInThisStep) % samplesInInterval;

        //recorder.addSamples(tempBuffer);
    }
    while( samplesProcessed < totalSamplesToProcess);

}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
void NinjamJamRoomController::processScheduledChanges(){
    if(newBpi > 0){
        currentBpi = newBpi;
        newBpi = -1;
        this->samplesInInterval = computeTotalSamplesInInterval();
        emit currentBpiChanged(currentBpi); //ui->topPanel->setBpi(currentBpi);

    }
    if(newBpm > 0){
        currentBpm = newBpm;
        newBpm = -1;
        this->samplesInInterval = computeTotalSamplesInInterval();
        this->metronomeTrackNode->setSamplesPerBeat(getSamplesPerBeat());
        emit currentBpmChanged((currentBpm)); //ui->topPanel->setBpm(currentBpm);
    }
    qDebug() << "SAMPLES IN INTERVAL: " << this->samplesInInterval;
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
long NinjamJamRoomController::getSamplesPerBeat(){
    return computeTotalSamplesInInterval()/currentBpi;
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
long NinjamJamRoomController::computeTotalSamplesInInterval(){
    double intervalPeriod =  60000.0 / currentBpm * currentBpi;
    int sampleRate = mainController->getAudioDriver()->getSampleRate();
    return (long)(sampleRate * intervalPeriod / 1000.0);
}


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//ninjam events

void NinjamJamRoomController::ninjamDisconnectedFromServer(Ninjam::Server server){
    Q_UNUSED(server);
    QMutexLocker locker(&mutex);
    mainController->removeTrack(-1);//remove metronome
    foreach(NinjamTrackNode* trackNode, trackNodes.values()){
        mainController->removeTrack(trackNode->getID());
        trackNode->deactivate();
    }
    trackNodes.clear();
    //emit disconnected(normalDisconnection);

}

void NinjamJamRoomController::ninjamUserLeave(Ninjam::User user){
     foreach (Ninjam::UserChannel* channel, user.getChannels()) {
        removeTrack(user, *channel);
     }
}

void NinjamJamRoomController::ninjamUserChannelCreated(Ninjam::User user, Ninjam::UserChannel channel){
    addTrack(user, channel);
}

void NinjamJamRoomController::ninjamUserChannelRemoved(Ninjam::User user, Ninjam::UserChannel channel){
    removeTrack(user, channel);
}

void NinjamJamRoomController::ninjamUserChannelUpdated(Ninjam::User user, Ninjam::UserChannel channel){
    QString uniqueKey = getUniqueKey(channel);
    QMutexLocker locker(&mutex);
    if(trackNodes.contains(uniqueKey)){
        NinjamTrackNode* trackNode = trackNodes[uniqueKey];
        emit channelNameChanged(user, channel, trackNode->getID());
    }

}

void NinjamJamRoomController::ninjamServerBpiChanged(short newBpi, short /*oldBpi*/){
    //this->samplesInInterval = computeTotalSamplesInInterval();
    this->newBpi = newBpi;
}

void NinjamJamRoomController::ninjamServerBpmChanged(short newBpm){
    //this->metronomeTrackNode->setSamplesPerBeat(getSamplesPerBeat());
    this->newBpm = newBpm;
}

void NinjamJamRoomController::ninjamAudiointervalCompleted(Ninjam::User user, int channelIndex, QByteArray encodedAudioData){
    //qDebug() << "audio available  Thread ID: " << QThread::currentThreadId();
    Ninjam::UserChannel channel = user.getChannel(channelIndex);
    QString channelKey = getUniqueKey(channel);
    QMutexLocker locker(&mutex);
    if(trackNodes.contains(channelKey)){
        NinjamTrackNode* trackNode = trackNodes[channelKey];
        trackNode->addVorbisEncodedInterval(encodedAudioData);
    }
    else{
        qWarning() << "o canal " << channelIndex << " do usuário " << user.getName() << " não foi encontrado no mapa!";
    }
}

void NinjamJamRoomController::ninjamAudiointervalDownloading(Ninjam::User user, int channelIndex, int downloadedBytes){
    Ninjam::UserChannel channel = user.getChannel(channelIndex);
    QString channelKey = getUniqueKey(channel);
    QMutexLocker locker(&mutex);
    if(trackNodes.contains(channelKey)){
        NinjamTrackNode* track = dynamic_cast<NinjamTrackNode*>( trackNodes[channelKey]);
        if(!track->isPlaying()){//track is not playing yet and receive the first interval bytes
            emit channelXmitChanged(track->getID(), true);
        }
    }
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

