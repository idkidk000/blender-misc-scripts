import bpy

for o in D.objects:
    if hasattr(o.animation_data, 'action'):
        for f in o.animation_data.action.fcurves:
            for p in f.keyframe_points:
                p.interpolation = 'ELASTIC'

