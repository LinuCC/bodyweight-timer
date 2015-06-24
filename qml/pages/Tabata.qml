import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import "../js/database.js" as DB

Page{
    id: exercisePage

    // property from lower stack page
    property variant    page
    property variant    title

    //  page internal properties
    //duration of active time
    property int activeTimeDuration: 0
    //save for reset. dont change
    property int activeTimeDurationPermanent: 0

    //duration of pause
    property int pauseDuration: 0
    //save for reset. dont change
    property int pauseDurationPermanent: 0

    //rounds per exercise
    property int roundsPerExercise: 0
    //save for reset. dont change
    // property int roundsPerExercisePermanent: 0

    //number of exercises
    property int numberOfExercises:  0
    //save for reset. dont change
    property int numberOfExercisesPermanent:  0

    //sum of all active times + pauses
    property int sumAllDurations: 0
    //save for reset. dont change
    property int sumAllDurationsPermanent: 0

    //track the current mode (active or pause)
    property int activeTimeRemaining: 0
    property int pauseTimeRemaining: 0
    property bool isActiveTime: true

    // Allow checking other modules if tabata is running or not
    property bool isTimerRunning: false

    //ProgressCircle
    property string progressCircleColor: "lime"

    //duration of an exercise: per every exercise (this are rounds too) -> roundsPerExercise * (activeTimeDuration+pauseDuration)

    function restartTimer() {
        resetTimer()
        continueTimer()
    }

    function resetTimer() {
        progressCircleTimer.running = false
        var val1 = DB.getDatabaseValuesFor(page, "value1")[0]
        var val2 = DB.getDatabaseValuesFor(page, "value2")[0]
        var val3 = DB.getDatabaseValuesFor(page, "value3")[0]
        var val4 = DB.getDatabaseValuesFor(page, "value4")[0]
        roundsPerExercise = val1
        activeTimeDuration = val2
        pauseDuration = val3
        numberOfExercisesPermanent = numberOfExercises = val4
        sumAllDurations = (activeTimeDuration + pauseDuration) *
            roundsPerExercise
        sumAllDurationsPermanent = sumAllDurations
        activeTimeRemaining = activeTimeDurationPermanent = activeTimeDuration
        pauseTimeRemaining = pauseDurationPermanent = pauseDuration
        isActiveTime = true
        progressCircleColor = "lime"
    }

    function continueTimer() {
        activeExercise = 'Tabata'
        activeExercisePage = exercisePage
        exerciseStatus = (activeTimeRemaining === 0) ? "Pause" : "Active"
        isTimerRunning = true
        progressCircleTimer.running = true
    }

    function pauseTimer() {
        exerciseStatus = 'Halted'
        isTimerRunning = false
        progressCircleTimer.running = false
    }

    function getTickingValue() {
        if(isActiveTime) {
            return activeTimeRemaining
        }
        else {
            return pauseTimeRemaining
        }
    }


    /*
     * Immediately start timer after page loaded
     */
    Component.onCompleted: {
        restartTimer()
    }

    SilicaFlickable {
        id: flickerList
        anchors.fill: parent

        PageHeader {
            id: header
            title: exercisePage.title
        }

        Audio {
            id: singleBell
            source: "sound/single_boxing-bell.wav"
        }
        Audio {
            id: doubleBell
            source: "sound/double_boxing-bell.wav"
        }

        Label {
            id: timerAsNumber
            color: Theme.highlightColor
            anchors.centerIn: progressCircle.Center
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : -(Theme.itemSizeMedium)
            text: {
                var displayMinutes = Math.floor(sumAllDurations/60);
                var displaySeconds = sumAllDurations-(displayMinutes*60)
                displayMinutes+"m "+displaySeconds+"s"
            }
            font.pixelSize: Theme.fontSizeHuge
        }

        ProgressCircle {
            id: progressCircle
            scale: 4
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : -(Theme.itemSizeMedium)
            progressColor: progressCircleColor
            backgroundColor: Theme.highlightDimmerColor
            Timer {
                id: progressCircleTimer
                interval: 1000
                repeat: true
                running: false
                onTriggered: {
                    //init
                    activeExercise = 'Tabata'
                    activeExercisePage = exercisePage
                    if(exercisePage.sumAllDurations === exercisePage.sumAllDurationsPermanent) {
                        var secondsOfCurrentTime = (exercisePage.sumAllDurationsPermanent % 60)
                        progressCircle.value = (100-(0.0166666666766666667 * secondsOfCurrentTime))
                    }
                    //calc the current time
                    progressCircle.value = (progressCircle.value + 0.0166666666766666667) % 1.0
                    exercisePage.sumAllDurations = exercisePage.sumAllDurations-1

                    //no more remaining time in this exercise?
                    if(exercisePage.sumAllDurations === 0)
                    {
                        //no more remaining exercises?
                        if(numberOfExercises === 1)
                        {
                            //Improvement: TripleBell?
                            singleBell.play()
                            doubleBell.play()
                            exercisePage.sumAllDurations = exercisePage.sumAllDurationsPermanent
                            exercisePage.numberOfExercises = exercisePage.numberOfExercisesPermanent
                            progressCircleTimer.restart()
                            progressCircleTimer.stop()
                            exerciseStatus = "Finished"
                    } else {
                            //reset timer and remove 1 of a exercise
                            exercisePage.numberOfExercises = exercisePage.numberOfExercises-1
                            if(numberOfExercises !== 0)
                            {
                                singleBell.play()
                            }
                            progressCircleTimer.stop()
                            exercisePage.sumAllDurations = exercisePage.sumAllDurationsPermanent
                            progressCircleTimer.restart()
                        }
                    } else {
                        //count remaining time
                        if(isActiveTime)
                        {
                            // console.log(activeTimeRemaining)
                            activeTimeRemaining = activeTimeRemaining-1
                            // console.log(activeTimeRemaining)
                        } else {
                            // console.log(pauseTimeRemaining)
                            pauseTimeRemaining = pauseTimeRemaining-1
                            // console.log(pauseTimeRemaining)

                        }


                        if(activeTimeRemaining === 0) //Enter pause-mode
                        {
                            exerciseStatus = "Pause"
                            doubleBell.play()
                            isActiveTime = false
                            progressCircleColor = "red"
                            activeTimeRemaining = activeTimeDurationPermanent
                        }
                        if(pauseTimeRemaining === 0) //Enter active-mode
                        {
                            exerciseStatus = "Active"
                            singleBell.play()
                            isActiveTime = true
                            progressCircleColor = "lime"
                            pauseTimeRemaining = pauseDurationPermanent
                        }
                    }
                }
            }
        }

        Label {
            id:currentRoundDisplay
            color: Theme.highlightColor
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset : (Theme.itemSizeMedium)+progressCircle.height
            text: {
                var currentRoundFromLowToHigh = (numberOfExercisesPermanent-numberOfExercises+1)
                if(currentRoundFromLowToHigh <= numberOfExercisesPermanent && isTimerRunning) {
                    "current excerise: " + currentRoundFromLowToHigh
                }
                else { "Go for it!" }
            }
            font.pixelSize: Theme.fontSizeMedium
        }


        Button {
            anchors.top: currentRoundDisplay.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Theme.paddingLarge
            text: {
                if(isTimerRunning) {
                    "Pause"
                } else {
                    "Start"
                }
            }
            onClicked: {
                if(isTimerRunning) {
                    pauseTimer()
                } else {
                    continueTimer()
                }
            // progressCircleTimer.running = !progressCircleTimer.running
            }

        }
    }
}
