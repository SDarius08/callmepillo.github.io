import os
import subprocess
import sys
import shutil

SCAD_FILE = "wirefollower.scad"    # Target OpenSCAD file
OUTPUT_DIR = "render_output"     # Folder for all generated files
THEME = "DeepOcean"              # Color scheme

# Static Render Settings
RES_STATIC = "2160,2160"         # 4K resolution
DISTANCE = "110"                 # Camera distance (Adjust to fit your object)

# Animation Settings
RES_ANIM = "1080,1080"           # 1080p for the GIF frames to save processing time
TOTAL_FRAMES = 36                # 36 frames = 10 degrees per frame for a 360 loop
FPS = 15                         # GIF playback speed

# Static Views: Name -> [Rot_X, Rot_Y, Rot_Z]
STATIC_VIEWS = {
    "1_top": "0,0,0",
    "2_bottom": "180,0,0",
    "3_back_edge": "90,0,0",
    "4_side": "90,0,90",
    "5_perspective": "55,0,45"
}
# ==========================================

def run_cmd(command):
    """Executes a terminal command and stops the script if it fails."""
    print(f"Executing: {' '.join(command)}")
    result = subprocess.run(command)
    if result.returncode != 0:
        print(f"\n[ERROR] Command failed: {' '.join(command)}")
        sys.exit(1)

def main():
    # 1. Setup the output environment
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    
    frames_dir = os.path.join(OUTPUT_DIR, "frames")
    if not os.path.exists(frames_dir):
        os.makedirs(frames_dir)

    # 2. Generate the 4 Static HQ Images
    print("\n--- Generating Static Views ---")
    for name, rotation in STATIC_VIEWS.items():
        output_file = os.path.join(OUTPUT_DIR, f"{name}.png")
        camera_args = f"0,9,0,{rotation},{DISTANCE}"
        
        cmd = [
            "openscad",
            "-o", output_file,
            f"--imgsize={RES_STATIC}",
            f"--colorscheme={THEME}",
            f"--camera={camera_args}",
            "--view=axes",
            "--autocenter",
            SCAD_FILE
        ]
        run_cmd(cmd)

    # 3. Generate the Animation Frames
    print("\n--- Generating Animation Frames ---")
    # Using the perspective camera angle for the animation
    anim_camera_args = f"0,9,0,55,0,45,{DISTANCE}" 
    
    for i in range(TOTAL_FRAMES):
        t_val = round(i / TOTAL_FRAMES, 4)
        frame_filename = os.path.join(frames_dir, f"frame_{i:02d}.png")
        
        cmd = [
            "openscad",
            "-o", frame_filename,
            "-D", f"$t={t_val}",
            f"--imgsize={RES_ANIM}",
            f"--colorscheme={THEME}",
            f"--camera={anim_camera_args}",
            "--autocenter",
            SCAD_FILE
        ]
        run_cmd(cmd)

    # 4. Stitch Frames into a GIF using FFmpeg
    print("\n--- Stitching GIF ---")
    input_pattern = os.path.join(frames_dir, "frame_%02d.png")
    output_gif = os.path.join(OUTPUT_DIR, "animated_model.gif")
    
    # FFmpeg command with high-quality palette generation filter
    cmd = [
        "ffmpeg",
        "-y",  # Overwrite output file if it exists
        "-framerate", str(FPS),
        "-i", input_pattern,
        "-vf", "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
        "-loop", "0",
        output_gif
    ]
    run_cmd(cmd)

    print(f"\n[SUCCESS] All done! Check the '{OUTPUT_DIR}' folder.")

    # 5. Cleanup Temporary Frames
    print("\n--- Shredding Evidence (Cleaning up frames) ---")
    try:
        shutil.rmtree(frames_dir)
        print(f"Successfully deleted: {frames_dir}")
    except OSError as e:
        print(f"Error deleting frames: {e.filename} - {e.strerror}")

if __name__ == "__main__":
    main()
