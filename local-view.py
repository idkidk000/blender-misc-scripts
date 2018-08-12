bl_info = {
    "name": "Local View",
    "version": (1, 0),
    "blender": (2, 80, 0),
    "location": "Numpad slash",
    "description": "Local View for Blender 2.8",
    "category": "Object"
}

import bpy


def main(context):
    hide = not(context.scene.local_view)
    for ob in context.scene.collection.objects:
        if ob.select_get():
            ob.hide_viewport = False
        else:
            ob.hide_viewport = hide
    for ob in context.scene.objects:
        if ob.select_get():
            ob.hide_viewport = False
        else:
            ob.hide_viewport = hide            
    context.scene.local_view = hide

class LocalView(bpy.types.Operator): 
    """Tooltip"""
    bl_idname = "object.local_view"
    bl_label = "Local view"

    @classmethod
    def poll(cls, context):
        return context.active_object is not None

    def execute(self, context):
        main(context)
        return {'FINISHED'}


def register():
    bpy.utils.register_class(LocalView)
    bpy.context.window_manager.keyconfigs.addon.keymaps.new(name='Object Mode').keymap_items.new(LocalView.bl_idname, 'NUMPAD_SLASH', 'PRESS')
    # Scene variables
    bpy.types.Scene.local_view = bpy.props.BoolProperty(
            default=False,
            description="Is local view active?"
            )


def unregister():
    bpy.utils.unregister_class(LocalView)
    for km in bpy.context.window_manager.keyconfigs.addon.keymaps:
        for kmi in km.keymap_items:
            km.keymap_items.remove(kmi)
    del bpy.types.Scene.local_view


if __name__ == "__main__":
    register()

    # test call
    bpy.ops.object.local_view()
