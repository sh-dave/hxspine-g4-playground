let playground = new Project('hxspine-g4-playground');

playground.addAssets('assets/**', {
	nameBaseDir: 'assets',
	destination: 'res/{dir}/{name}',
	name: '{dir}/{name}',
});

//playground.addDefine('hxspine_kha_profiler');
playground.addParameter('--times');

playground.localLibraryPath = 'libs';
playground.addLibrary('hxspine');
await playground.addProject('libs/hxspine-g4');

playground.addSources('src')

resolve(playground);
