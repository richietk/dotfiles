pragma Singleton
import Quickshell

Singleton {
    id: root

    function shellSingleQuoteEscape(str) {
        return String(str).replace(/'/g, "'\\''");
    }

    function getDomain(url) {
        const match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/);
        return match ? match[1] : null;
    }

    function escapeHtml(str) {
        if (typeof str !== 'string')
            return str;
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
    }

    function cleanCliphistEntry(str: string): string {
        return str.replace(/^\d+\t/, "");
    }

    function cleanPrefix(str, prefix) {
        if (str.startsWith(prefix))
            return str.slice(prefix.length);
        return str;
    }

    function cleanOnePrefix(str, prefixes) {
        for (let i = 0; i < prefixes.length; ++i) {
            if (str.startsWith(prefixes[i]))
                return str.slice(prefixes[i].length);
        }
        return str;
    }
}
