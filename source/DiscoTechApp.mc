using Toybox.Application;
using Toybox.WatchUi;

//! DiscoTech - A sound-reactive visual experience for Garmin watches.
//! Uses the accelerometer to detect bass vibrations and renders colorful
//! animated patterns on the watch display.
class DiscoTechApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new DiscoTechView();
        var delegate = new DiscoTechDelegate(view);
        return [view, delegate];
    }
}
