#!/usr/bin/env python3
import colorsys
import typing
import sys
import pathlib

Color = typing.Tuple[float, float, float]

colors: typing.List[Color] = []

max_saturation = False
interpolation = 0

textured_shader_file = pathlib.Path(__file__).parent.resolve() / "textured_chroma.fsh"
standard_shader_file = pathlib.Path(__file__).parent.resolve() / "standard_chroma.fsh"

source_file = pathlib.Path(sys.argv[1]).read_text().splitlines() if len(sys.argv) > 1 else None
source_file_idx = 0
while True:
    if source_file:
        if source_file_idx == len(source_file):
            break
        color = source_file[source_file_idx]
        source_file_idx += 1
    else:
        color = input("Enter a flag color (or an option, like maxsaturation, or interpolation=10): ")

    if not color and not source_file:
        print("Empty color -> loop finished")
        break
    
    if color == "maxsaturation":
        max_saturation = True
        continue

    if color.startswith("interpolation="):
        interpolation = int(color[len("interpolation="):])
        continue

    if not color.startswith("#"):
        print("Invalid color. Use a hex code like #abcdef")
        continue

    rgb = int(color[1:], 16)
    r = (rgb >> 16) & 255
    g = (rgb >> 8) & 255
    b = (rgb) & 255
    colors.append((r / 255, g / 255, b / 255))

hues = []
saturations = []
brightnesses = []

for col in colors:
    h,s,v = colorsys.rgb_to_hsv(*col)
    hues.append(h)
    saturations.append(s)
    brightnesses.append(v)

textured_text = textured_shader_file.read_text()


textured_newlines: typing.List[str] = []
is_skipping_lines = False
for line in textured_text.splitlines():
    if line == "// FLAG_BEGIN":
        is_skipping_lines = True
    elif line == "// FLAG_END":
        textured_newlines.append("#define HUE_INIT (" + ','.join(map(str, hues)) + ")")
        textured_newlines.append("#define SATURATION_INIT (" + ','.join(map(str, saturations)) + ")")
        textured_newlines.append("#define BRIGHTNESS_INIT (" + ','.join(map(str, brightnesses)) + ")")
        textured_newlines.append("#define FLAG_SIZE " + str(len(hues)))
        textured_newlines.append("#define MAX_SATURATION " + ("true" if max_saturation else "false"))
        textured_newlines.append("#define INTERPOLATION_LEVEL " + str(interpolation))
        is_skipping_lines = False
    elif is_skipping_lines:
        continue
    textured_newlines.append(line)
    
print("Textured shader:")
for line in textured_newlines:
    print(line)
    
      
textured_shader_file.write_text('\n'.join(textured_newlines))


standard_newlines: typing.List[str] = []
is_skipping_lines = False
standard_text = standard_shader_file.read_text()
for line in standard_text.splitlines():
    if line == "// FLAG_BEGIN":
        is_skipping_lines = True
    elif line == "// FLAG_END":
        standard_newlines.append("#define HUE_INIT (" + ','.join(map(str, hues)) + ")")
        standard_newlines.append("#define SATURATION_INIT (" + ','.join(map(str, saturations)) + ")")
        standard_newlines.append("#define BRIGHTNESS_INIT (" + ','.join(map(str, brightnesses)) + ")")
        standard_newlines.append("#define FLAG_SIZE " + str(len(hues)))
        standard_newlines.append("#define MAX_SATURATION " + ("true" if max_saturation else "false"))
        standard_newlines.append("#define INTERPOLATION_LEVEL " + str(interpolation))
        is_skipping_lines = False
    elif is_skipping_lines:
        continue
    standard_newlines.append(line)

print("Standard shader:")
for line in standard_newlines:
    print(line)

standard_shader_file.write_text('\n'.join(standard_newlines))
