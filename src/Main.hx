package;

import spine.*;
import spine.g4.*;
import spine.g4.utils.*;

@:structInit class SpineObject {
	public var skeleton: Skeleton;
	public var state: AnimationState;
	public var playtime: Float;
}

@:structInit class Scene {
	public var atlas: String;
	public var scene: String;
}

class Main {
	public static function main() {
		kha.System.start({ title: 'hxspine-g4' }, function( _ ) {
			kha.Assets.loadEverything(function() {
				new Main();
			});
		});
	}

	var lastTime = 0.0;
	var isPlaying = true;

	final camera: OrthoCamera;
	final objs: Array<SpineObject> = [];

	final coloredPipeline = null;
	final coloredPipelineMVP = null;
	final texturedPipeline = null;
	final texturedPipelineMVP = null;
	final twoColorTexturedPipeline = null;
	final twoColorTexturedPipelineMVP = null;

	final batcher: PolygonBatcher;
	final skeletonRenderer: SkeletonRenderer;
	final batcher2c: PolygonBatcher;
	final skeletonRenderer2c: SkeletonRenderer;
	final debugShapes: ShapeRenderer;
	final debugSkeletonRenderer = new SkeletonDebugRenderer();

	function mapAtlas( path ) return switch path {
		case 'atlas1.png': new TextureImpl(kha.Assets.images.example1_atlas1);
		case 'atlas2.png': new TextureImpl(kha.Assets.images.example1_atlas2);
		case 'atlas12.png': new TextureImpl(kha.Assets.images.example1_atlas12);
		case other: throw 'unmapped path `$other`';
	}

	function new() {
		camera = new OrthoCamera(800, 600);

		final coloredStructure = DefaultPipelines.createColoredVertexStructure();
		coloredPipeline = DefaultPipelines.createColoredPipeline(coloredStructure);
		coloredPipelineMVP = coloredPipeline.getConstantLocation(DefaultPipelines.MVP_MATRIX);

		final texturedStructure = DefaultPipelines.createTexturedVertexStructure();
		texturedPipeline = DefaultPipelines.createTexturedPipeline(texturedStructure);
		texturedPipelineMVP = texturedPipeline.getConstantLocation(DefaultPipelines.MVP_MATRIX);
		final texturedPipelineTexUnit = texturedPipeline.getTextureUnit(DefaultPipelines.SAMPLER);

		final twoColorTexturedStructure = DefaultPipelines.createTwoColorTexturedVertexStructure();
		twoColorTexturedPipeline = DefaultPipelines.createTwoColorTexturedPipeline(twoColorTexturedStructure);
		twoColorTexturedPipelineMVP = twoColorTexturedPipeline.getConstantLocation(DefaultPipelines.MVP_MATRIX);
		final twoColorTexturedPipelineTexUnit = twoColorTexturedPipeline.getTextureUnit(DefaultPipelines.SAMPLER);

		batcher = new PolygonBatcher(texturedStructure, texturedPipelineTexUnit);
		skeletonRenderer = new SkeletonRenderer(false);
		skeletonRenderer.vertexEffect = new spine.vertexeffects.JitterEffect(20, 20);

		batcher2c = new PolygonBatcher(twoColorTexturedStructure, twoColorTexturedPipelineTexUnit);
		skeletonRenderer2c = new SkeletonRenderer(true);
		// skeletonRenderer2c.vertexEffect = new spine.vertexeffects.JitterEffect(20, 20);

		debugShapes = new ShapeRenderer(coloredStructure);

		debugSkeletonRenderer.drawBones = true;
		debugSkeletonRenderer.drawRegionAttachments = false;
		debugSkeletonRenderer.drawBoundingBoxes = false;
		debugSkeletonRenderer.drawMeshHull = false;
		debugSkeletonRenderer.drawMeshTriangles = false;
		debugSkeletonRenderer.drawPaths = false;
		debugSkeletonRenderer.drawSkeletonXY =  false;
		debugSkeletonRenderer.drawClipping = false;

		final skeletonJson = [
			new SkeletonJson(new spine.AtlasAttachmentLoader(new TextureAtlas(
				kha.Assets.blobs.example1_atlas2_atlas.toString(),
				mapAtlas
			))),
			new SkeletonJson(new spine.AtlasAttachmentLoader(new TextureAtlas(
				kha.Assets.blobs.example2_spineboy_atlas.toString(),
				path -> new TextureImpl(kha.Assets.images.example2_spineboy)
			))),
			new SkeletonJson(new spine.AtlasAttachmentLoader(new TextureAtlas(
				kha.Assets.blobs.example1_atlas1_atlas.toString(),
				mapAtlas
			))),
		];

		final demosJson = [
			haxe.Json.parse(kha.Assets.blobs.example1_demos_json.toString()),
			kha.Assets.blobs.example2_spineboy_ess_json.toString(),
			haxe.Json.parse(kha.Assets.blobs.example1_demos_json.toString()),
		];

		final todo = [
			{ nr: 0, o: 'tank', anim: 'drive', x: 3000, y: 0, sx: 1.0, sy: 1.0 },
			{ nr: 0, o: 'armorgirl', anim: 'animation', x: -1000, y: 100, sx: 0.5, sy: 0.5 },
			{ nr: 0, o: 'greengirl', anim: 'animation', x: 0, y: 0, sx: 1.0, sy: 1.0 },
			{ nr: 0, o: 'orangegirl', anim: 'animation', x: 1000, y: 0, sx: 1.5, sy: 1.5 },
			{ nr: 0, o: 'stretchyman', anim: 'idle', x: -1700, y: 0, sx: 1.5, sy: 1.5 },
			{ nr: 0, o: 'vine', anim: 'animation', x: -1700, y: 300, sx: 1.5, sy: 1.5 },
			{ nr: 0, o: 'owl', anim: 'idle', x: 2000, y: 300, sx: 1.5, sy: 1.5 },

			{ nr: 1, o: null, anim: 'walk', x: -1500, y: 1500, sx: 1.5, sy: 1.5 },

			{ nr: 2, o: 'spineboy', anim: 'portal', x: 1000, y: 1000, sx: 1.5, sy: 1.5 },
		];

		for (it in todo) {
			final nr = it.nr;
			final skeletonData = it.o != null
				? skeletonJson[nr].readSkeletonData(haxe.Json.stringify(Reflect.field(demosJson[nr], it.o)))
				: skeletonJson[nr].readSkeletonData(demosJson[nr]);
			final skeleton = new Skeleton(skeletonData);
			final state = new AnimationState(new AnimationStateData(skeleton.data));
			state.setAnimation(0, it.anim, true);
			state.apply(skeleton);
			skeleton.x = it.x;
			skeleton.y = it.y;
			skeleton.scaleX = it.sx;
			skeleton.scaleY = it.sy;
			skeleton.updateWorldTransform();

			objs.push({
				skeleton: skeleton,
				state: state,
				playtime: 0.0,
			});
		}

		kha.System.notifyOnFrames(draw);
		kha.Scheduler.addTimeTask(update, 0, 1 / 60);
		lastTime = kha.Scheduler.time();

		var mmbDown = false;

		kha.input.Mouse.get().notify(
			(b, x, y) -> {
				if (b == 2) {
					mmbDown = true;
				}
			},
			(b, x, y) -> {
				if (b == 2) {
					mmbDown = false;
				}
			},
			(x, y, dx, dy) -> {
				if (mmbDown) {
					final m = 0.01;
					// trace('dx=$dx dy=$dy x=${camera.position.x} y=${camera.position.y}');
					camera.position.x += dx > 0 ? m : dx < 0 ? -m : 0;
					camera.position.y += dy > 0 ? m : dy < 0 ? -m : 0;
				}
			},
			d -> {
				camera.zoom += d;
			},
			() -> {}
		);

	}

	function update() {
		final now = kha.Scheduler.time();
		final delta = now - lastTime;
		lastTime = now;

		if (isPlaying) {
			// timeLine.set(playTime / animationDuration);

			for (o in objs) {
				var animationDuration = o.state.getCurrent(0).animation.duration;
				o.playtime += delta;

				while (o.playtime >= animationDuration) {
					o.playtime -= animationDuration;
				}

				// o.skeleton.x += 10;
				o.state.update(delta);
				o.state.apply(o.skeleton);
				o.skeleton.updateWorldTransform();
			}
		}
	}

	function draw( fbs: Array<kha.Framebuffer> ) {
		final fb = fbs[0];
		final ww = kha.System.windowWidth();
		final wh = kha.System.windowHeight();

		camera.viewportWidth = ww;
		camera.viewportHeight = wh;
		camera.update();

		final g4 = fb.g4;
		g4.begin();
			g4.clear(kha.Color.fromBytes(90, 95, 100), 0, 0);
			// final tankx = objs[0].skeleton.findBone("tankRoot").worldX;
			// camera.position.x = 0;//tankx - 300;

			{ // objects
				g4.setPipeline(texturedPipeline);
				g4.setMatrix(texturedPipelineMVP, camera.projectionView);

				// batcher.begin(g4);
				// 	for (o in objs) {
				// 		skeletonRenderer.draw(batcher, o.skeleton, -1, -1);
				// 	}
				// batcher.end();

				batcher2c.begin(g4);
					for (o in objs) {
						skeletonRenderer2c.draw(batcher2c, o.skeleton, -1, -1);
					}
				batcher2c.end();
			}

			{ // debug lines
				g4.setPipeline(coloredPipeline);
				g4.setMatrix(coloredPipelineMVP, camera.projectionView);

				debugShapes.begin(g4);
					for (o in objs) {
						debugSkeletonRenderer.draw(debugShapes, o.skeleton);
					}
				debugShapes.end();
			}
		g4.end();
	}
}
