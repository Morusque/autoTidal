(
s.options.numBuffers = 1024 * 512 * 2;
s.options.memSize = 8192 * 16 * 2;
s.options.maxNodes = 1024 * 16 * 2;
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.waitForBoot {
	~dirt = SuperDirt(2, s);
	~dirt.loadSoundFiles("D:/project/current/tidal/autoTidal/bank/*");
	s.sync;
	thisProcess.openUDPPort(57120);
	~dirt.start(57120, [0, 0]);
};
s.latency = 1.5;
);
