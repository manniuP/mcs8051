// MCS-251 调试扩展：把 VSCode 的 DAP 会话接到 tools/mcs_dap.py。
const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function toWsl(p) {
    const m = /^([A-Za-z]):[\\/](.*)$/.exec(p);
    if (m) {
        return '/mnt/' + m[1].toLowerCase() + '/' + m[2].replace(/\\/g, '/');
    }
    return p.replace(/\\/g, '/');
}

function findAdapter(root) {
    const candidates = [
        path.join(root, 'mcs251', 'tools', 'mcs_dap.py'),
        path.join(root, 'tools', 'mcs_dap.py'),
    ];
    for (const c of candidates) {
        if (fs.existsSync(c)) {
            return c;
        }
    }
    return candidates[0];
}

function activate(context) {
    context.subscriptions.push(
        vscode.debug.registerDebugAdapterDescriptorFactory('mcs251', {
            createDebugAdapterDescriptor(session) {
                const cfg = session.configuration || {};
                let adapter = cfg.adapterPath;
                if (!adapter) {
                    const folders = vscode.workspace.workspaceFolders;
                    const root = folders && folders.length ? folders[0].uri.fsPath : process.cwd();
                    adapter = findAdapter(root);
                }
                if (cfg.useWsl === false) {
                    return new vscode.DebugAdapterExecutable('python', [adapter]);
                }
                return new vscode.DebugAdapterExecutable('wsl', ['python3', toWsl(adapter)]);
            }
        })
    );
}

function deactivate() { }

module.exports = { activate, deactivate };
