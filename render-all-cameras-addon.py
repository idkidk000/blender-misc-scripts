import os, bpy, bgl, blf, sys
from bpy import data, ops, props, types, context

# ####################################################################################################
#
# this is not my code. originally posted at 
# https://blenderartists.org/t/render-camera-script-changing-execution-context-breaks-for-loop/1116355 
# by Forrest_Gimp
#
# ####################################################################################################

# setup renderbutton for stills
class RenderAllCameras(bpy.types.Operator):
	bl_idname = "render_cams.button"
	bl_label = "All stills"

	def execute(self, context):
		print('')
		print('Rendering stills for all cameras...')
		renderStuff(False)
		return{'FINISHED'}

# setup renderbutton for animations
class RenderAllAnims(bpy.types.Operator):
	bl_idname = "render_anims.button"
	bl_label = "All animations"

	def execute(self, context):
		print('')
		print('Rendering animations for all cameras...')
		renderStuff(True)
		return{'FINISHED'}

# render scene from all cameras
def renderStuff(animToggle):
	# get current scene, renderpath/filename and active camera
	currentScene = bpy.data.scenes[bpy.data.scenes.keys()[0]]
	renderPath = currentScene.render.filepath
	previousCamera = currentScene.camera

	# Loop all objects and find Cameras
	for obj in currentScene.objects:
		# Find cameras
		if ( obj.type =='CAMERA') :
			print("Rendering camera ["+obj.name+"]")  
			print(bpy.context.scene.render.display_mode)
			# Set camera as active and create filename for image
			currentScene.camera = obj
			currentScene.render.filepath = renderPath+"_"+obj.name
			# Render cameraview
			bpy.ops.render.render(animation=animToggle, write_still=True )#it works, but no preview, only progess in the console

	# reset renderpath/filename and active camera
	currentScene.render.filepath = renderPath
	currentScene.camera = previousCamera
	print('Done!')
	
# add section to render-panel
class RenderAllCamerasPanel(bpy.types.Panel):
	bl_label = "Render all cameras"
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = "render"
	bl_options = {'DEFAULT_CLOSED'}
	
	def draw(self, context):
		layout = self.layout
		row = layout.row(align=True)
		col = layout.column(align=True)
		col.operator_context = 'INVOKE_DEFAULT'
		row.operator("render_cams.button",icon = 'RENDER_STILL')		
		row.operator("render_anims.button",icon = 'RENDER_ANIMATION')
		
# register the class
def register():
	bpy.utils.register_class(RenderAllCameras)
	bpy.utils.register_class(RenderAllAnims)
	bpy.utils.register_class(RenderAllCamerasPanel)

def unregister():
	bpy.utils.unregister_class(RenderAllCameras)
	bpy.utils.unregister_class(RenderAllAnims)
	bpy.utils.unregister_class(RenderAllCamerasPanel)