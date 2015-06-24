function secondsToTimeString(seconds) {
    var displayMinutes = Math.floor(seconds / 60);
    var displaySeconds = seconds - (displayMinutes * 60)
    return displayMinutes + "m " + displaySeconds + "s"
}