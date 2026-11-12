use std::{env, fs};

use zed_extension_api::{
    self as zed, LanguageServerId, LanguageServerInstallationStatus, Result, settings::LspSettings,
};

// Shared with the WebVTT extension, which starts its own instance
const PACKAGE: &str = "media-language-server";
const SERVER_PATH: &str = "node_modules/media-language-server/dist/server.js";

struct M3uExtension {
    did_find_server: bool,
}

impl M3uExtension {
    fn server_path(&mut self, id: &LanguageServerId) -> Result<String> {
        let exists = fs::metadata(SERVER_PATH).is_ok_and(|stat| stat.is_file());
        if self.did_find_server && exists {
            return Ok(SERVER_PATH.to_string());
        }

        zed::set_language_server_installation_status(
            id,
            &LanguageServerInstallationStatus::CheckingForUpdate,
        );
        let version = zed::npm_package_latest_version(PACKAGE)?;
        if !exists || zed::npm_package_installed_version(PACKAGE)?.as_ref() != Some(&version) {
            zed::set_language_server_installation_status(
                id,
                &LanguageServerInstallationStatus::Downloading,
            );
            // Offline or a failed update: keep using the installed version
            if let Err(error) = zed::npm_install_package(PACKAGE, &version)
                && !exists
            {
                return Err(error);
            }
            if !fs::metadata(SERVER_PATH).is_ok_and(|stat| stat.is_file()) {
                return Err(format!("{PACKAGE} installed without {SERVER_PATH}"));
            }
        }

        self.did_find_server = true;
        Ok(SERVER_PATH.to_string())
    }
}

impl zed::Extension for M3uExtension {
    fn new() -> Self {
        Self {
            did_find_server: false,
        }
    }

    fn language_server_command(
        &mut self,
        id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        // A local checkout, via `lsp.m3u-language-server.binary` in settings
        if let Some(binary) = LspSettings::for_worktree(id.as_ref(), worktree)
            .ok()
            .and_then(|settings| settings.binary)
            && let Some(path) = binary.path
        {
            return Ok(zed::Command {
                command: path,
                args: binary
                    .arguments
                    .unwrap_or_else(|| vec!["--stdio".to_string()]),
                env: binary.env.unwrap_or_default().into_iter().collect(),
            });
        }

        let server = env::current_dir()
            .map_err(|error| error.to_string())?
            .join(self.server_path(id)?);
        Ok(zed::Command {
            command: zed::node_binary_path()?,
            args: vec![server.to_string_lossy().into_owned(), "--stdio".to_string()],
            env: Default::default(),
        })
    }
}

zed::register_extension!(M3uExtension);
