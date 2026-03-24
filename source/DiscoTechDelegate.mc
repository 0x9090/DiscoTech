using Toybox.WatchUi;
using Toybox.Lang;

//! Handles button input to cycle through visual patterns.
class DiscoTechDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DiscoTechView;

    function initialize(view as DiscoTechView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    //! UP button or swipe up: next pattern
    function onNextPage() as Boolean {
        _view.nextPattern();
        return true;
    }

    //! DOWN button or swipe down: previous pattern
    function onPreviousPage() as Boolean {
        _view.previousPattern();
        return true;
    }

    //! SELECT/ENTER button: toggle auto-cycle mode
    function onSelect() as Boolean {
        _view.toggleAutoCycle();
        return true;
    }

    //! BACK button: exit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    //! Tap on touchscreen watches: trigger a "beat" flash
    function onTap(clickEvent as ClickEvent) as Boolean {
        _view.triggerManualBeat();
        return true;
    }
}
