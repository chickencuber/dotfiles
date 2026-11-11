pragma Singleton
import Quickshell.Services.Notifications

NotificationServer {
    keepOnReload: false

    bodySupported: true
    bodyImagesSupported: true
    imageSupported: true

    actionsSupported: true
    actionIconsSupported: true
    inlineReplySupported: true
    bodyMarkupSupported: true

    onNotification: function (notification) {
        notification.tracked = true;
    }
}
