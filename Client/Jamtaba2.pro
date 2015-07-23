#parece que o primeiro buffer resampleado nunca tem todas as amostras que preciso por causa do filter width

#Acho que meu problema está relacionado com o filter_width.

#Tenho que ver se depois de enviar a flag de final eu não precisa injetar zeros novamente no resampler

#quando eu não passo a flag de final para o resampler ele retorna zero. Acho que no meu caso
#eu sempre preciso enganar ele dizendo que é o final para que ele gere alguma coisa na saída.

#Se eu passo a flag de final sempre como verdadeira ele sempre me retorna as amostras. O que é
#estranho é que eu mando duas vezes a mesma sequencia de input mas recebo outputs diferentes

#In general, the algorithm for resampling to a higher frequency is:
#* maintain a 'cursor': a floating-point sample index, into the source sample
#* for each sample, advance the cursor by (sourceSampleRate/targetSampleRate), which will be < 1.0
#* interpolate data from the source sample according to the cursor position using the interpolation method of your choice; this will generally involve a polynomial using a small number of source samples around the cursor
#For resampling to a lower frequency, the process is similar but the source sample should be lowpass filtered to attenuate everything above half the target sample rate before interpolation.


#meu resampler tem problema:  se eu passo um desiredOutLength maior que o tamanho real do
    #buffer resampleado ele fica gerando lixo até atingir o desiredOutLenght.

    #Mas mesmo que eu corrija isso e limite a quantida de amostras na saída (o correto), sobrarão
    #algumas amostras não usadas no buffer interno do resampler. Nao tenho certeza se ele vai
    #me cuspir essas amostras restantes nas próximas chamadas. Mas dá pra testar isso passando
    #um input zerado e ver o que o resampler bota na saída.


#testei com a fast em 64 e 96 KHz, o resultado fica muito ruim e da pra perceber que o intervalo termina antes de chegar no próximo
    #tempo 1.  Tenho duas hipóteses:

#Hipótese 1 - Quando maior o número de callbacks maior setá o número de arredondamentos que o resampler faz, o que no total vai perder muitas
    #amostras. Isso explicaria porque com um buffer grande eu não sinto os estalos.
    #Pelo teste que fiz com a fast track (64 e 96 KHz) acho que estou consumindo mais amostras do que deveria em cada callback.
    #O problema é que devo estar descartando as amotras excedentes, fazendo com que o intervalo acabe antes.


#Hipótese 2 - É possível que eu esteja sobrescrevendo a mesma área de memória com callbacks consecutivos. Tirei os statics dos
    #buffers temporários no NinjamController mas não mudou nada. Talvez a forma que eu estou usando o internalBuffer para fazer
    #o resampling possa dar problema;



#mudei para um buffer size grande e os estalos do decoder quase sumiram. Com 4096 eu não ouvi estalos.
    #Com 1024 eu ouvi estalos apenas no início dos intervalos.
    #Com 512 já comecei a ouvir estalos pelo meio do intervalo.
        #ideia: mensurar o tempo de resampling

    #o tempo de processamento do ninjamTrackNode foi de no máximo 2ms (incluindo resampling). Não é tanto assim, e ouvi estalos
        #em momentos onde o tempo de processamento foi inferior aos 2ms, então acho que o problema não é esse.
        #Poder que algum mutex está travando a thread do audio?
        #desativei o timer da GUI para garantir que a thread da gui não parasse o audio, mas os estalos continuaram
        #Eu desativei todos os mutexes da Classe AudioNode e parece que melhorou bastante, mas continua
        #Mesmo com a fast track, usando 128 e 48 KHz ainda tem estalo, não deveria.



#Transmitindo a 44.1 no reaninjam e recebendo em 48 no Jamtaba deu muitos estalos durante o decoding, problema no resampling?
    #dá mais estalos no início do intervalo, talvez esteja perdendo amostras.

#será que o resampler não acumula as amostras? Eu estou achando que sim. Se
#eu passar out.frameLenght para ele mas o buffer resampleado tiver out.lenght + 1 samples
#eu acho que ele vai guardar essa última amostra no buffer interno, mas eu teria
#que sair do loop do resampler exatamente em out.lenght


#Estava com o metronomo mutado, alterei as configurações de áudio, quando voltei o metronomo saiu do mute

#Mudança no resampling
#implementar resample no metronomo?
#implementar resample no stream das salas

#no ninjamJamController estou recriando o tempInBuffer em cada callback. Otimizar isso.

#ver o construtor do mainController, acho que comentei a inserção do roomStreamer na lista de nodes, por isso não está tocando os streams
#acho que quando fico alternando entre os streams das salas não está funcionando muito bem, parece que o botão ficou pressionado.
#acho que o stream do ninjamer não está rolando


#se ligo a fast enquanto o Jamtaba está aberto ela não aparece na lista. Algum tipo de cache na portaudio?

#mudei do asio4all para FAst track mas as entradas continuaram como "microfones"


#Entrei em uma sala com uns 5 caras e estava usando 25:% da minha CPU.
#Entrei na mesma sala usando o Reaninjam e não chegou a 1% da minha CPU. Mas depois eu descobri que se não estiver encodando
#o reaninjam usa pouca CPU. O bicho pega mesmo quando tem que encodar. Mesmo assim acho que estou usando muita CPU.
    #Quanto de cpu usa sem entrar em uma sala?
    #Quanto de CPU usa para encoder?
    #E os decoders, acrescentam muita coisa na CPU? Posso criar um monte de canais no reaninjam e ver o que acontece.

#O consumo de memória está aumentando sem parar e não consegui achar o erro. Preciso de um Valgrind.


#leak - quando deletar um encode do map de encoders? Como saber lá no NinjamController que o usuário está com um canal a menos?

#Deu tanto trabalho implementar o visual do metronomo que agora enquanto eu não botar várias opções de progresso no intervalo eu não
    #vou morrer em paz:
    # 1 - Elipse (está pronto)
    # 2 - Círculo (praticamente pronto, só aproveitar o código da ellipse).
    # 3 - Espiral (deixei o código comentado)
    # 4 - Fancy display (a classe já está pronta);


#não rolou resampling para o metronomo?

#estava bugando o parser da lista de servers públicos no servidor

#GAz deu a ideia de fazer um translate usando o site do google translate e HTML scrapping.

#Comentei com o Marcello sobre a ideia de criar um segundo chat para mensagens privadas.

#quando solo uma das inputs as outras também são enviadas. Ou seja, o solo está atuando apenas localmente. Faz sentido mudar isso?

#drummix stereo abre, mas o drummix multi dá pau. Talvez a quantidade de canais esteja gerando problema.

#se adiciono um plugin e fecho dá pau - Só acontece com alguns plugins. Como os plugins grandes não estão carregando eu acho
    #que deve ser alguma coisa relacionada com as funções de iniciallização dos plugins que eu não estou invocando.

#quando mando scanear arquivos de programa dá pau em algumas DLLs. ACho que um
#try catch poderia melhorar isso

#o botão clear cache não dá nenhum feedback. Seria legal mostrar a lista de plugins
#que estão na cache e depois limpar essa lista

#nome do plugin bypassado aparece embaixo do botãode bypass, problema no layout?

#tenho dúvida se os ID dos canais ninjam não ficar bagunçados quando tiver mais usuários na sala
#testei em uma sala com 2 players (3 canais) estava ok, inclusive o agrupemento fechou 100%


#dar feedback quando o usuário escolher noInput. Deixar a pista esmaecida seria legal.
#Usar setEnabled não funcionou porque desabilita inclusive o combo de selação, o que
#impossibilita que o usuário volte a deixar a pista ativa.

#nomes grandes estragam os nome dos canais nas entradas, os nomes dos canais ninjam, etc. Uma AutoElidedQLabel seria legal.


#também preciso tratar a situação onde o usuário está usando midi como entrada e o driver midi é alterado nas preferencias


#como vou permitir vários devices midi? Pelo que vi no portaudio.h o único jeito seria abrir vários streams midi, um para cada device.
#acho que é melhor deixar isso para mais adiante, por que também terei que mudar a forma como estou lendo as mensagens midi e passando
#elas adiante. Como cada pista local vai poder ler de um midi device diferente eu acho que a solução seria criar um MidiBuffer e disponibilizá-lo
#para o processReplacing como eu fiz com o SamplesBuffer. Esse MidiBuffer teria vários canais, cada canal contendo as mensagens midi de um device
#diferente

#deu pau com o kontakt também. Só está carregando plugins pequenos?

#deu pau quando tentei colocar o Addictive Drums

#abri a aplicação com a fast track e deu pau porque 192 é uma SR inválida. Tenho que pedir as SR válidas para cada device.
#já aproveitar para pedir os buffer sizes


#consegui entrar no jamtaba com a fast track desligada. O canal apareceu como "not connected"

#não consegui votar para trocar bpi

#preciso testar nome de usuário com caracter especial para ver se o utf está funcionando

#não está lembrando das entradas estereo com a fast track


# a mensagem de crowded está errada?


#separar o carregamento do plugin VST da instância. No momento uma instância é criada e depois é que o plugin é carregado. Pra mim
#isso é um bad design

#Preciso mudar a cor de fundo da pistas de acordo com o tipo. Pistas locais de uma cor, metronomo de outra, pistas ninjam de outra.
#Talvez seja uma boa hora para usar HSV e ter variações

#tirar spacers dos títulos das seções?

# MIDI funcionando, mas se seleciono o midi da FAST track e depois volto para o SPS ele não funciona mais. Testar com o controlador AKAI também para ver

#dialogo de IO do midi - testar novamente, ver se a seleção do midi device está funcionando

#não consegui resolver o bug que acontece quando as pistas são removidas, por hora apenas comentei a linha que delete as pistas no NinjamJamRoomController. Ou seja, a memoria não está sendo liberada.
#Agora estou usando vector<float> para guardar as amostras, ver o que acontece.

# Quando botei o reverb depois do B4 ouvi o reverb na entrada do mic mas não no B4, o encadeamento tem problema
#Na verdade preciso repensar isso, não faz sentido ter midi e áudio ao mesmo tempo em uma pista

# não estou chamando o startProcess nos VSTs, isso pode bugar VSTs que utilizam

# drummix multi deu problema na mixagem dos canais, acho que só consegui ouvir o bumbo e o vazamendo das outras peças

#buga tudo se não tem conexão com a internet

#Resampling
    #Ainda tem um probleminha nos início de alguns intervalos, mas só acontece em
    #algumas combinações de SR e como está já está bem aceitável. Eu não estou corrigindo
    #a perda de amostras que vai acontecendo aos poucos, por isso chega no final do intervalo
    #pode dar algumas amostras de diferença.

#tem um bug quando o bpi está em 4

#chat ninjam
    #problema nos caracteres especiais - tenho que testar se o envio está correto e depois testar a recepção

# feature - botão para ouvir o stream dos server e ver como está a mix geral

#audo update: https://wiki.qt.io/Qt-Installer-Framework

#mapa com os jogadores? É possível?

#PLUGINS NATIVOS
    # mostrar plugins nativos
    # Melhorar o visual do Delay, os LineEdit estão grandes demais
    # Seria interessante possibilitar que os parâmetros do delay sejam alterados através dos lineEdit

#Magnus e Doublebass agradeceram pelo esforço e disseram que ter um canal de backing track é muito importante.

# - Coisas legais para implementar: fazer um plugin de delay para iniciar a saga dos plugins nativos do Jamtaba
# - O stream do ninjamer.com não é mono como achei que era, mas está dando problema


#quando trocar de bpi ver se ainda é possível usar a mesma acentuação procurando pelo valor
#antigo na nova lista

#BUGS relacionados com o diálogo de audioIO:
#1 - quando seleciono as entradas sPDIF da fast track a aplicação encerra
#2 - quando seleciono saídas que não são 1 e 2 dá um crash também.
#3 - Com a fast track quando seleciono as entradas e simplesmente volto para a tela de audio IO o valor do segundo combo está bugado.
#4 - preciso testar com a fonte da fast track para ver se os outros canais estão realmente funcionando


#-------------------------------------------------
#
# Project created by QtCreator 2015-01-13T11:05:00
#
#-------------------------------------------------

QT       +=  gui  network

#DEFINES += QT_NO_CAST_FROM_ASCII
#DEFINES += QT_NO_CAST_TO_ASCII

QMAKE_CXXFLAGS += -D _CRT_SECURE_NO_WARNINGS #-Wno-unused-parameter

CONFIG += c++11

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = Jamtaba2
TEMPLATE = app

MAIN = src/jamtaba/main.cpp
#MAIN = src/jamtaba/ninjam/main.cpp


HEADERS += \
    #nvwa/debug_new.h \
    #--------------------------------
#    #--------------------------------
    src/jamtaba/audio/core/AudioDriver.h \
    src/jamtaba/audio/core/AudioNode.h \
    src/jamtaba/audio/core/AudioMixer.h \
    src/jamtaba/audio/core/PortAudioDriver.h \
#    #--------------------------------
    src/jamtaba/gui/widgets/PeakMeter.h \
    src/jamtaba/gui/widgets/WavePeakPanel.h \
#    #--------------------------------
    src/jamtaba/loginserver/LoginService.h \
    src/jamtaba/loginserver/JsonUtils.h \
#    #--------------------------------
    src/jamtaba/MainController.h \
    src/jamtaba/JamtabaFactory.h \
#    #--------------------------------
    src/jamtaba/ninjam/protocol/ServerMessageParser.h \
    src/jamtaba/ninjam/protocol/ServerMessages.h \
    src/jamtaba/ninjam/protocol/ClientMessages.h \
    src/jamtaba/ninjam/User.h \
    src/jamtaba/ninjam/Service.h \
    src/jamtaba/ninjam/Server.h \
#    #--------------------------------
    src/jamtaba/loginserver/natmap.h \
    src/jamtaba/audio/RoomStreamerNode.h \
    src/jamtaba/audio/codec.h \
    src/jamtaba/gui/LocalTrackView.h \
    src/jamtaba/gui/JamRoomViewPanel.h \
    src/jamtaba/gui/MainFrame.h \
    src/jamtaba/gui/FxPanel.h \
    src/jamtaba/gui/FxPanelItem.h \
    src/jamtaba/audio/core/plugins.h \
    src/jamtaba/gui/plugins/guis.h \
    src/jamtaba/audio/vst/PluginFinder.h \
    src/jamtaba/audio/vst/VstPlugin.h \
    src/jamtaba/audio/vst/vsthost.h \
    src/jamtaba/midi/MidiDriver.h \
    src/jamtaba/midi/portmididriver.h \
    src/jamtaba/gui/pluginscandialog.h \
    src/jamtaba/gui/PreferencesDialog.h \
    src/jamtaba/gui/NinjamRoomWindow.h \
    src/jamtaba/gui/BaseTrackView.h \
    src/jamtaba/audio/NinjamTrackNode.h \
    src/jamtaba/gui/NinjamTrackView.h \
    src/jamtaba/audio/MetronomeTrackNode.h \
    src/jamtaba/gui/NinjamPanel.h \
    src/jamtaba/gui/FancyProgressDisplay.h \
    src/jamtaba/audio/Resampler.h \
    src/jamtaba/audio/vorbis/VorbisDecoder.h \
    src/jamtaba/ninjam/UserChannel.h \
    src/jamtaba/audio/core/SamplesBuffer.h \
    src/jamtaba/gui/BusyDialog.h \
    src/jamtaba/audio/core/AudioPeak.h \
    src/jamtaba/geo/IpToLocationResolver.h \
    src/jamtaba/gui/ChatPanel.h \
    src/jamtaba/gui/ChatMessagePanel.h \
    src/jamtaba/audio/SamplesBufferResampler.h \
    src/jamtaba/audio/samplesbufferrecorder.h \
    src/jamtaba/audio/vorbis/VorbisEncoder.h \
    src/jamtaba/gui/Highligther.h \
    src/jamtaba/persistence/Settings.h \
    src/jamtaba/Utils.h \
    src/jamtaba/gui/TrackGroupView.h \
    src/jamtaba/gui/LocalTrackGroupView.h \
    src/jamtaba/NinjamController.h \
    src/jamtaba/gui/CircularIntervalProgressDisplay.h


SOURCES += \
    $$MAIN \
#    nvwa/debug_new.cpp \
#-----------------------------------------
##------------------------------------------------
    src/jamtaba/audio/core/AudioDriver.cpp \
    src/jamtaba/audio/core/AudioNode.cpp \
    src/jamtaba/audio/core/AudioMixer.cpp \
    src/jamtaba/audio/core/PortAudioDriver.cpp \
    src/jamtaba/audio/RoomStreamerNode.cpp \
##------------------------------------------------
    src/jamtaba/gui/widgets/PeakMeter.cpp \
    src/jamtaba/gui/widgets/WavePeakPanel.cpp \
##------------------------------------------------
    src/jamtaba/JamtabaFactory.cpp \
    src/jamtaba/MainController.cpp \
##------------------------------------------------
    src/jamtaba/loginserver/LoginService.cpp \
    src/jamtaba/loginserver/JsonUtils.cpp \
##------------------------------------------------
    src/jamtaba/ninjam/protocol/ServerMessages.cpp \
    src/jamtaba/ninjam/protocol/ClientMessages.cpp \
    src/jamtaba/ninjam/protocol/ServerMessageParser.cpp \
    src/jamtaba/ninjam/Server.cpp \
    src/jamtaba/ninjam/Service.cpp \
    src/jamtaba/ninjam/User.cpp \
    src/jamtaba/gui/LocalTrackView.cpp \
    src/jamtaba/gui/FxPanel.cpp \
    src/jamtaba/gui/FxPanelItem.cpp \
    src/jamtaba/audio/core/plugins.cpp \
    src/jamtaba/audio/codec.cpp \
    src/jamtaba/gui/plugins/guis.cpp \
    src/jamtaba/gui/JamRoomViewPanel.cpp \
    src/jamtaba/gui/MainFrame.cpp \
    src/jamtaba/audio/vst/PluginFinder.cpp \
    src/jamtaba/audio/vst/VstPlugin.cpp \
    src/jamtaba/audio/vst/vsthost.cpp \
    src/jamtaba/midi/MidiDriver.cpp \
    src/jamtaba/gui/PreferencesDialog.cpp \
    src/jamtaba/gui/PluginScanDialog.cpp \
    src/jamtaba/midi/PortMidiDriver.cpp \
    src/jamtaba/gui/NinjamRoomWindow.cpp \
    src/jamtaba/gui/BaseTrackView.cpp \
    src/jamtaba/audio/NinjamTrackNode.cpp \
    src/jamtaba/gui/NinjamTrackView.cpp \
    src/jamtaba/audio/MetronomeTrackNode.cpp \
    src/jamtaba/gui/NinjamPanel.cpp \
    src/jamtaba/gui/FancyProgressDisplay.cpp \
    src/jamtaba/audio/Resampler.cpp \
    src/jamtaba/audio/vorbis/VorbisDecoder.cpp \
    src/jamtaba/ninjam/UserChannel.cpp \
    src/jamtaba/audio/core/SamplesBuffer.cpp \
    src/jamtaba/gui/BusyDialog.cpp \
    src/jamtaba/audio/core/AudioPeak.cpp \
    src/jamtaba/geo/IpToLocationResolver.cpp \
    src/jamtaba/gui/ChatPanel.cpp \
    src/jamtaba/gui/ChatMessagePanel.cpp \
    src/jamtaba/audio/SamplesBufferResampler.cpp \
    src/jamtaba/audio/samplesbufferrecorder.cpp \
    src/jamtaba/audio/vorbis/VorbisEncoder.cpp \
    src/jamtaba/gui/Highligther.cpp \
    src/jamtaba/persistence/Settings.cpp \
    src/jamtaba/gui/TrackGroupView.cpp \
    src/jamtaba/gui/LocalTrackGroupView.cpp \
    src/jamtaba/NinjamController.cpp \
    src/jamtaba/gui/CircularIntervalProgressDisplay.cpp

FORMS += \
    src/jamtaba/gui/PreferencesDialog.ui \
    src/jamtaba/gui/PluginScanDialog.ui \
    src/jamtaba/gui/MainFrame.ui \
    src/jamtaba/gui/JamRoomViewPanel.ui \
    src/jamtaba/gui/NinjamRoomWindow.ui \
    src/jamtaba/gui/BaseTrackView.ui \
    src/jamtaba/gui/NinjamPanel.ui \
    src/jamtaba/gui/BusyDialog.ui \
    src/jamtaba/gui/ChatPanel.ui \
    src/jamtaba/gui/ChatMessagePanel.ui \
    src/jamtaba/gui/TrackGroupView.ui


#macx: LIBPATH += /Users/Eliesr/Qt5.4.0/5.4/clang_64/lib \
#win32:LIBPATH += C:/Qt/Qt5.4.0/Tools/mingw491_32/i686-w64-mingw32/lib/ \
#win32:LIBPATH += C:\Qt\Qt5.4.2\5.4\msvc2013\lib

VST_SDK_PATH = "D:/Documents/Estudos/ComputacaoMusical/Jamtaba2/VST3_SDK/pluginterfaces/vst2.x/"


INCLUDEPATH += src/jamtaba/gui                  \
               src/jamtaba/gui/widgets          \
               $$VST_SDK_PATH                   \
               $$PWD/libs/includes/portaudio    \
               $$PWD/libs/includes/portmidi     \
               $$PWD/libs/includes/ogg          \
               $$PWD/libs/includes/vorbis       \
               $$PWD/libs/includes/libresample  \
               $$PWD/libs/includes/minimp3      \
               $$PWD/libs/includes/libmaxmind   \


win32: LIBS +=  -L$$PWD/libs/win32-mingw/ -lportaudio -lportmidi -lvorbisfile -lvorbis -lvorbisenc -logg -lminimp3 -lmaxminddb -lresample \

win32: LIBS +=  -lwinmm     \
                -lole32     \
                -lws2_32    \

RESOURCES += src/jamtaba/resources/jamtaba.qrc

#INCLUDEPATH += $$PWD/libs/includes/portaudio
#DEPENDPATH += $$PWD/libs/includes/portaudio
