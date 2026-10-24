import Gio from 'gi://Gio';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

import { TahoeClockManager, TahoeActivitiesManager } from './modules/clock.js';
import { TahoeGlobalMenuManager } from './modules/globalmenu/manager.js';
import { TahoeKimpanelManager } from './modules/kimpanel/manager.js';
import { TahoeBlurManager } from './modules/blur/manager.js';

export default class UbuntuTahoeExtension extends Extension {
    constructor(metadata) {
        super(metadata);
        this._clockManager = null;
        this._activitiesManager = null;
        this._globalMenuManager = null;
        this._kimpanelManager = null;
        this._blurManager = null;
        this._suiteSettings = null;
    }

    _getSchemaSettings(schemaId) {
        try {
            return this.getSettings(schemaId);
        } catch (e) {
            try {
                const schemaDir = this.dir.get_child('schemas').get_path();
                const source = Gio.SettingsSchemaSource.new_from_directory(
                    schemaDir,
                    Gio.SettingsSchemaSource.get_default(),
                    false
                );
                const schema = source.lookup(schemaId, true);
                if (schema) {
                    return new Gio.Settings({ settings_schema: schema });
                }
            } catch (err) {
                console.warn(`[UbuntuTahoe] Custom schema lookup error for ${schemaId}:`, err);
            }
            return new Gio.Settings({ schema_id: schemaId });
        }
    }

    enable() {
        console.log('[UbuntuTahoe] Enabling macOS Tahoe suite...');
        this._suiteSettings = this.getSettings();

        // 1. Clock Position (Move to right box, offset 20)
        try {
            const pos = this._suiteSettings.get_int('clock-position');
            const offset = this._suiteSettings.get_int('clock-offset');
            this._clockManager = new TahoeClockManager();
            this._clockManager.enable(pos, offset);
        } catch (err) {
            console.error('[UbuntuTahoe] Failed to reposition clock:', err);
        }

        // 2. Hide Activities button
        try {
            if (this._suiteSettings.get_boolean('hide-activities')) {
                this._activitiesManager = new TahoeActivitiesManager();
                this._activitiesManager.enable();
            }
        } catch (err) {
            console.error('[UbuntuTahoe] Failed to hide activities:', err);
        }

        // 3. Global Menu (Application Menu bar)
        try {
            if (this._suiteSettings.get_boolean('enable-globalmenu')) {
                const globalMenuSettings = this._getSchemaSettings('org.gnome.shell.extensions.globalmenu');
                this._globalMenuManager = new TahoeGlobalMenuManager(
                    this.path,
                    globalMenuSettings,
                    this.metadata.uuid
                );
                this._globalMenuManager.enable();
            }
        } catch (err) {
            console.error('[UbuntuTahoe] Failed to enable Global Menu:', err);
        }

        // 4. Input Method Panel (Kimpanel)
        try {
            if (this._suiteSettings.get_boolean('enable-kimpanel')) {
                const kimSettings = this._getSchemaSettings('org.gnome.shell.extensions.kimpanel');
                this._kimpanelManager = new TahoeKimpanelManager(kimSettings);
                this._kimpanelManager.enable();
            }
        } catch (err) {
            console.error('[UbuntuTahoe] Failed to enable Kimpanel:', err);
        }

        // 5. Blur (Overview & AppFolders)
        try {
            if (this._suiteSettings.get_boolean('enable-blur')) {
                const blurSettings = this._getSchemaSettings('org.gnome.shell.extensions.blur-my-shell');
                this._blurManager = new TahoeBlurManager(blurSettings);
                this._blurManager.enable();
            }
        } catch (err) {
            console.error('[UbuntuTahoe] Failed to enable Blur Manager:', err);
        }

        console.log('[UbuntuTahoe] macOS Tahoe suite enabled successfully.');
    }

    disable() {
        console.log('[UbuntuTahoe] Disabling macOS Tahoe suite...');

        if (this._blurManager) {
            try {
                this._blurManager.disable();
            } catch (err) {
                console.error('[UbuntuTahoe] Error disabling blur:', err);
            }
            this._blurManager = null;
        }

        if (this._kimpanelManager) {
            try {
                this._kimpanelManager.disable();
            } catch (err) {
                console.error('[UbuntuTahoe] Error disabling kimpanel:', err);
            }
            this._kimpanelManager = null;
        }

        if (this._globalMenuManager) {
            try {
                this._globalMenuManager.disable();
            } catch (err) {
                console.error('[UbuntuTahoe] Error disabling global menu:', err);
            }
            this._globalMenuManager = null;
        }

        if (this._activitiesManager) {
            try {
                this._activitiesManager.disable();
            } catch (err) {
                console.error('[UbuntuTahoe] Error restoring activities:', err);
            }
            this._activitiesManager = null;
        }

        if (this._clockManager) {
            try {
                this._clockManager.disable();
            } catch (err) {
                console.error('[UbuntuTahoe] Error restoring clock position:', err);
            }
            this._clockManager = null;
        }

        this._suiteSettings = null;
        console.log('[UbuntuTahoe] macOS Tahoe suite disabled successfully.');
    }
}
