// -*- mode: js; js-indent-level: 4; indent-tabs-mode: nil -*-

import {DockManager} from './docking.js';
import {Main} from './dependencies/shell/ui.js';
import {Extension} from './dependencies/shell/extensions/extension.js';

export let dockManager;

export default class UbuntuTahoeDockExtension extends Extension.Extension {
    enable() {
        console.log('[UbuntuTahoeDock] Enabling macOS Tahoe Dock...');
        if (!dockManager) {
            try {
                dockManager = new DockManager(this);
            } catch (e) {
                console.error('[UbuntuTahoeDock] Error initializing DockManager:', e);
            }
        }
    }

    disable() {
        console.log('[UbuntuTahoeDock] Disabling macOS Tahoe Dock...');
        try {
            dockManager?.destroy();
            dockManager = null;
        } catch (e) {
            console.error('[UbuntuTahoeDock] Failed to destroy dockManager:', e);
        }
    }
}
