import { Kimpanel } from './service.js';

export class TahoeKimpanelManager {
    constructor(settings) {
        this._settings = settings;
        this._kimpanel = null;
    }

    enable() {
        console.log('[UbuntuTahoe > kimpanel] Enabling Input Method Panel...');
        if (!this._kimpanel) {
            try {
                this._kimpanel = new Kimpanel(this._settings);
            } catch (err) {
                console.error('[UbuntuTahoe > kimpanel] Error starting Kimpanel:', err);
            }
        }
    }

    disable() {
        console.log('[UbuntuTahoe > kimpanel] Disabling Input Method Panel...');
        if (this._kimpanel) {
            try {
                this._kimpanel.destroy();
            } catch (err) {
                console.error('[UbuntuTahoe > kimpanel] Error destroying Kimpanel:', err);
            }
            this._kimpanel = null;
        }
    }
}
