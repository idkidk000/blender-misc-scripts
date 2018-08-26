bl_info = {
    "name": "Wireframe View",
    "version": (1, 0),
    "blender": (2, 80, 0),
    "location": "Z key",
    "description": "Wireframe View for Blender 2.8",
    "category": "Object"
}

import bpy

def main(context):
    new_setting = not(bpy.context.space_data.overlay.show_wireframes)
    bpy.context.space_data.overlay.show_wireframes = new_setting
    bpy.context.space_data.shading.show_xray = new_setting

class WireframeView(bpy.types.Operator):
    """Toggle wireframe view"""
    bl_idname = "object.wireframe_view"
    bl_label = "Wireframe view"

    @classmethod
    def poll(cls, context):
        return True #context.space_data.type == 'VIEW_3D'

    def execute(self, context):
        main(context)
        return {'FINISHED'}

addon_keymaps = []
def register():
    bpy.utils.register_class(WireframeView)
    
    km = bpy.context.window_manager.keyconfigs.addon.keymaps.new(name='3D View Generic', space_type='VIEW_3D')
    kmi = km.keymap_items.new(WireframeView.bl_idname, 'Z', 'PRESS')
    addon_keymaps.append((km,kmi))

def unregister():
    bpy.utils.unregister_class(WireframeView)
    
    for km, kmi in addon_keymaps:
        km.keymap_items.remove(kmi)

if __name__ == "__main__":
    register()
