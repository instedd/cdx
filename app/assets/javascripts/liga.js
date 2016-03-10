/* A polyfill for browsers that don't support ligatures. */
/* The script tag referring to this file must be placed before the ending body tag. */

/* To provide support for elements dynamically added, this script adds
   method 'icomoonLiga' to the window object. You can pass element references to this method.
*/
(function () {
    'use strict';
    function supportsProperty(p) {
        var prefixes = ['Webkit', 'Moz', 'O', 'ms'],
            i,
            div = document.createElement('div'),
            ret = p in div.style;
        if (!ret) {
            p = p.charAt(0).toUpperCase() + p.substr(1);
            for (i = 0; i < prefixes.length; i += 1) {
                ret = prefixes[i] + p in div.style;
                if (ret) {
                    break;
                }
            }
        }
        return ret;
    }
    var icons;
    if (!supportsProperty('fontFeatureSettings')) {
        icons = {
            'alert': '&#xe900;',
            'algorithm': '&#xe901;',
            'arrowdown': '&#xe902;',
            'arrow-left': '&#xe903;',
            'arrow-right': '&#xe904;',
            'arrow-up': '&#xe905;',
            'bell': '&#xe906;',
            'building': '&#xe907;',
            'cartridge': '&#xe908;',
            'checkbox-outline': '&#xe909;',
            'checkbox': '&#xe90a;',
            'expand': '&#xe90b;',
            'collapse': '&#xe90c;',
            'circle-minus': '&#xe90d;',
            'circle-plus': '&#xe90e;',
            'close': '&#xe90f;',
            'comment': '&#xe910;',
            'culture': '&#xe911;',
            'document': '&#xe912;',
            'download': '&#xe913;',
            'earth': '&#xe914;',
            'info-outline': '&#xe915;',
            'ellipsis': '&#xe916;',
            'error': '&#xe917;',
            'ethernet': '&#xe918;',
            'eye': '&#xe919;',
            'forward': '&#xe91a;',
            'help': '&#xe91b;',
            'horizontal-thumb-outline': '&#xe91c;',
            'horizontal-thumb': '&#xe91d;',
            'info': '&#xe91e;',
            'ink-dropper': '&#xe91f;',
            'key': '&#xe920;',
            'keyboard-arrow-down': '&#xe921;',
            'keyboard-arrow-left': '&#xe922;',
            'keyboard-arrow-right': '&#xe923;',
            'keyboard-arrow-up': '&#xe924;',
            'link': '&#xe925;',
            'location': '&#xe926;',
            'lock': '&#xe927;',
            'mail': '&#xe928;',
            'map': '&#xe929;',
            'mask': '&#xe92a;',
            'microscope': '&#xe92b;',
            'circle-minus-outline': '&#xe92c;',
            'circle-plus-outline': '&#xe92d;',
            'patient': '&#xe92e;',
            'pencil': '&#xe92f;',
            'plus': '&#xe930;',
            'power': '&#xe931;',
            'print': '&#xe932;',
            'punchcard': '&#xe933;',
            'radio-button-outline': '&#xe934;',
            'radio-button': '&#xe935;',
            'refresh': '&#xe936;',
            'search': '&#xe937;',
            'strip': '&#xe938;',
            'table': '&#xe939;',
            'tag': '&#xe93a;',
            'test-tube': '&#xe93b;',
            'test': '&#xe93c;',
            'ascending': '&#xe93d;',
            'descending': '&#xe93e;',
            'tick': '&#xe93f;',
            'time-span': '&#xe940;',
            'trash': '&#xe941;',
            'trend': '&#xe942;',
            'break': '&#xe943;',
            'update': '&#xe944;',
            'upload': '&#xe945;',
            'user': '&#xe946;',
            'wrap': '&#xe947;',
            'wrench': '&#xe948;',
          '0': 0
        };
        delete icons['0'];
        window.icomoonLiga = function (els) {
            var classes,
                el,
                i,
                innerHTML,
                key;
            els = els || document.getElementsByTagName('*');
            if (!els.length) {
                els = [els];
            }
            for (i = 0; ; i += 1) {
                el = els[i];
                if (!el) {
                    break;
                }
                classes = el.className;
                if (/icon-/.test(classes)) {
                    innerHTML = el.innerHTML;
                    if (innerHTML && innerHTML.length > 1) {
                        for (key in icons) {
                            if (icons.hasOwnProperty(key)) {
                                innerHTML = innerHTML.replace(new RegExp(key, 'g'), icons[key]);
                            }
                        }
                        el.innerHTML = innerHTML;
                    }
                }
            }
        };
        window.icomoonLiga();
    }
}());
