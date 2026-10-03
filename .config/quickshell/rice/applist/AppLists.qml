import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property list<string> pinnedApps: []
    property list<string> recentApps: []

    readonly property string statePath:
        Quickshell.env("HOME") + "/.local/state/quickshell/rice/"

    FileView {
        id: pinnedFile

        path: root.statePath + "pinned-apps.json"
        watchChanges: true

        onLoadedChanged: {
            if (!loaded)
                return;

            try {
                const parsed = JSON.parse(text());

                if (Array.isArray(parsed))
                    root.pinnedApps = parsed;
            } catch (e) {
                root.pinnedApps = [];
            }
        }
    }

    FileView {
        id: recentFile

        path: root.statePath + "recent-apps.json"
        watchChanges: true

        onLoadedChanged: {
            if (!loaded)
                return;

            try {
                const parsed = JSON.parse(text());

                if (Array.isArray(parsed))
                    root.recentApps = parsed;
            } catch (e) {
                root.recentApps = [];
            }
        }
    }

    function savePinned(): void {
        pinnedFile.setText(JSON.stringify(root.pinnedApps));
    }

    function saveRecent(): void {
        recentFile.setText(JSON.stringify(root.recentApps));
    }

    function isPinned(id: string): bool {
        return root.pinnedApps.includes(id);
    }

    function togglePin(id: string): void {
        if (root.isPinned(id)) {
            root.pinnedApps = root.pinnedApps.filter(
                appId => appId !== id
            );
        } else {
            root.pinnedApps = [
                ...root.pinnedApps,
                id
            ];
        }

        root.savePinned();
    }

    function addRecent(id: string): void {
        root.recentApps = [
            id,
            ...root.recentApps.filter(
                appId => appId !== id
            )
        ].slice(0, 5);

        root.saveRecent();
    }
}
