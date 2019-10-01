#!/bin/python3
import os
import argparse
import time
import sys
import shutil
from subprocess import DEVNULL, STDOUT, check_call

# Constant
const_cachedir = os.getenv("HOME") + "/.cache/pywalblur"

# functions

def get_current_workspace():
    return os.popen("xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}'").read()

# # # # # Bluring section # # # # #
def anim_blur(walls_path, wallpaper_path, animation):
    if not animation:
        check_call(["hsetroot", "-cover", walls_path + "/" + os.path.splitext(os.path.basename(wallpaper_path))[0] + "5.png"], stdout=DEVNULL, stderr=STDOUT)
    else:
        for i in range(0, 6):
            check_call(["hsetroot", "-cover", walls_path + "/" + os.path.splitext(os.path.basename(wallpaper_path))[0] + str(i) + ".png"], stdout=DEVNULL, stderr=STDOUT)

def anim_unblur(walls_path, wallpaper_path, animation):
    if not animation:
        check_call(["hsetroot", "-cover", walls_path + "/" + os.path.splitext(os.path.basename(wallpaper_path))[0] + "0.png"], stdout=DEVNULL, stderr=STDOUT)
    else:
        for i in range(5, -1, -1):
            check_call(["hsetroot", "-cover", walls_path + "/" + os.path.splitext(os.path.basename(wallpaper_path))[0] + str(i) + ".png"], stdout=DEVNULL, stderr=STDOUT)

def get_window_number(workspace):
    return os.popen(f"echo \"$(wmctrl -l)\" | awk -F\" \" \'{{print $2}}\' | grep {workspace}").read().count('\n')

def loop_blur(wallpaper_path, sleeptime, animation):
    blured = False
    walls_path = const_cachedir + "/" + os.path.splitext(os.path.basename(wallpaper_path))[0]
    while True:
        window_open = get_window_number(get_current_workspace())
        if window_open:
            if not blured:
                anim_blur(walls_path, wallpaper_path, animation)
                blured = True
        else:
            if blured:
                anim_unblur(walls_path, wallpaper_path, animation)
                blured = False
        time.sleep(sleeptime)
# # # # # Bluring section # # # # #


def limits_refresh(arg):
    try:
        f = float(arg)
    except ValueError:
        raise argparse.ArgumentTypeError("Must be a floating point number")
    if f < 0 or f > 1:
        raise argparse.ArgumentTypeError("Argument must be 0 > [val] < 1 ")
    return f

def delete_wallpaper_cache(arg):
    filename = os.path.splitext(os.path.basename(arg))[0]
    if os.path.exists(const_cachedir + "/" + filename):
        print("Remove \'%s\' cache ? [Y/N] " % (filename), end='')
        if input().upper() == "Y":
            shutil.rmtree(const_cachedir + "/" + filename)
            print("Removed cache for \'%s\'" % (filename))
        else:
            print("Aborting.")
            exit(0)
    else:
        print("No cache found for \'%s\'" % (filename))
        exit(0)

def clear_cache():
    print("Remove all cached wallpaper ? [Y/N] ",end='')
    if input().upper() == "Y":
        print("Removed cache")
        shutil.rmtree(const_cachedir)
        os.mkdir(const_cachedir)            
    else:
        print("Aborting.")

def create_cache(filepath):
    blur_step = ["2", "5", "8", "10"]
    filename = os.path.splitext(os.path.basename(filepath))[0]
    print("Generating cache for %s, this may take some time..." % (filepath))
    if os.path.exists(const_cachedir + "/" + filename):
        print("Cache for \'%s\' aleready exist skipping" % (const_cachedir + "/" + filename))
        return
    else:
        os.mkdir(const_cachedir + "/" + filename)
        print("generating frame 0/5...")
        check_call(["convert", filepath, const_cachedir + "/" + filename + "/" + filename + "0" + ".png"], stdout=DEVNULL, stderr=STDOUT)
        for i in range(1, 5):
            print("generating frame %d/5..." % (i))
            check_call(["convert", "-blur", "0x" + blur_step[i - 1], filepath, const_cachedir + "/" + filename + "/" + filename + str(i) + ".png"], stdout=DEVNULL, stderr=STDOUT)
        print("generating frame 5/5...")
        check_call(["convert", "-scale","10%", "-blur", "0x2", "-resize", "1000%", filepath, const_cachedir + "/" + filename + "/" + filename + "5.png"], stdout=DEVNULL, stderr=STDOUT)
    print("Finished generating cache for %s" % (filepath))

# Parser
parser = argparse.ArgumentParser(description="Blur wallpaper on window open.")
parser.add_argument('-r', '--refresh-rate', type=limits_refresh, default=0.3, help="interval of check")
parser.add_argument('-q', '--quiet', action='store_true', help="no print")
parser.add_argument('-c', '--create-cache', type=create_cache, help="create cache without launching")
parser.add_argument('-a', '--animation', action='store_true', help="add 'animation'(experimental)")
bluring_grp = parser.add_mutually_exclusive_group()
bluring_grp.add_argument('-w', '--wallpaper', type=str, default="<none>", help="wallpaper path")
bluring_grp.add_argument('-g', '--wallpapergif', type=str, default="<none>", help="wallpaper path as gif(not yet implemented)")
bluring_grp.add_argument('-d', '--delete', type=delete_wallpaper_cache, help="delete cached wallpaper corresponding to path")
bluring_grp.add_argument('-C', '--clear', action='store_true', help="clear all cached wallpaper")

if len(sys.argv[1:]) == 0:
    parser.print_usage()
    parser.exit()

args = parser.parse_args()

if __name__ == "__main__":
    if not os.path.exists(const_cachedir):
        os.mkdir(const_cachedir)
        print("Created cache directory in \'%s\'\n" % (const_cachedir) if not args.quiet else '', end='')
    if args.clear:
        clear_cache()
        exit(0)
    if args.wallpaper != "<none>":
        create_cache(args.wallpaper)
        loop_blur(args.wallpaper, args.refresh_rate, args.animation)
    else:
        exit(0)