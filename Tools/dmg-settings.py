"""Create a Finder installation window without driving the Finder UI."""
import os
import subprocess

files = [defines["app"]]
symlinks = {"Applications": "/Applications"}
background = defines["background"]
icon = defines["icon"]
format = "UDZO"
compression_level = 9
filesystem = "HFS+"
default_view = "icon-view"
window_rect = ((180, 140), (720, 540))
icon_locations = {"LanguageSwitcher.app": (190, 252), "Applications": (530, 252)}
icon_size = 112
text_size = 13
label_pos = "bottom"
arrange_by = None
hide_extensions = []  # Changing bundle FinderInfo would break strict signing checks.
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_item_info = False
show_icon_preview = False
include_icon_view_settings = True
include_list_view_settings = False


def create_hook(mount_point, options):
    subprocess.run([
        "/usr/bin/codesign", "--verify", "--deep", "--strict",
        os.path.join(mount_point, "LanguageSwitcher.app"),
    ], check=True)
