(
OSCdef('RESET',{
	arg msg;
	s.freeAll;
	CmdPeriod.run;
	msg.postln;
	~main.value;
},"/reset");

~main = {

	TempoClock.default.tempo_(40/60);
	~t = TempoClock.default.tempo;

	~chordsList = [ ];
	~rootNote = 1000;
	~f = [];
	~store = [];
	~isPlaying = false;
	~rootCounter = 0;

	~bassBus = Bus.audio(s,2);
	~padBus = Bus.audio(s,2);
	~arpBus = Bus.audio(s,2);
	~delayBus = Bus.audio(s,2);

	~masterVolume = Volume.new(s, 0, 2);
	~bassVolume = 1;
	~padVolume = 1;
	~arpVolume = 1;

	SynthDef(\padSynth,{
		arg out=0, note=60, rel=1, amp=1, outBus=0;
		var env, sig1, unison, pan, freq;
		freq = note.midicps;
		unison = LFNoise1.kr(1!8).bipolar(1/8).midiratio;
		env = EnvGen.kr(Env.perc(0.2, rel, 0.2), doneAction: Done.freeSelf);
		sig1 =  SinOsc.ar(freq*unison, 0, env);
		sig1 = Splay.ar(sig1);
		sig1 = 2*FreeVerb2.ar(sig1[0], sig1[1], 0.7, 0.9, 0.1);
		Out.ar(outBus, amp*Balance2.ar(sig1[0], sig1[1], LFNoise1.kr(1).bipolar(0.7)));
	}).add;

	SynthDef(\bassSynth,{
		arg note=48, outBus=0, gate=0, amp=1;
		var freq=100, env, osc, lpf, hpf, sub, unison, sig;
		freq = note.midicps;
		unison = LFNoise1.kr(1!3).bipolar(1/3).midiratio;
		env = EnvGen.kr(Env.asr(1, 1, 1), gate:gate , doneAction: Done.freeSelf);
		osc = Saw.ar(freq*unison);
		sub = SinOsc.ar(freq,0,0.5);
		lpf = RLPF.ar(osc, 5*freq+SinOsc.kr(0.1).bipolar(100), 0.5);
		hpf = HPF.ar(lpf, 4*freq);
		Out.ar(outBus, amp*(Splay.ar(hpf*0.4)+Pan2.ar(sub*0.5))*(-7).dbamp)
	}).add;

	SynthDef(\riser,{
		arg a=300, framerate=30, gate=1;
		var pink, filt, env, rev, trig,
		sub, saw, unison, bass, mix;

		trig = Trig.kr(gate, a/framerate);
		env = EnvGen.kr(Env.asr(a/framerate, 1, 0, 1), gate: gate);

		pink = WhiteNoise.ar([env, env]);
		filt = LPF.ar(pink, 2000*(env+0.5));
		filt = Splay.ar(filt);

		sub = SinOsc.ar(45, 0, env*SinOsc.kr(0.1, 0, 0.1, 0.9));
		unison = LFNoise1.kr(1!4).bipolar(1/4).midiratio;
		saw = Saw.ar(45*unison, env);
		saw = LPF.ar(saw, 5000);
		saw = HPF.ar(saw, 45*3);
		bass = (-6).dbamp*(Splay.ar(saw*0.5)+Pan2.ar(sub));

		mix = 2*bass+filt*0.5;

		rev = FreeVerb2.ar(mix[0], mix[1], 0.8, 1, 0.1);

		Out.ar(0, rev*(-10).dbamp);
	}).add;

	SynthDef(\arp,{
		arg outBus=0, note=72;
		var osc, flt, env, verb;
		env = EnvGen.ar(Env.perc(0.01,1.0), doneAction:Done.freeSelf);
		osc = SinOsc.ar(note.midicps*[1.01,0.99], mul:env);

		Out.ar(outBus, osc*(-4).dbamp)
	}).add;

	SynthDef(\delay,{
		arg inBus, outBus=0;
		var input, dly, verb, mix=0.6;
		input = In.ar(inBus,1);
		dly = Greyhole.ar(input,
			delayTime: ~t/4,
			damp: 0.3,
			size: 0.8,
			diff: 0.707,
			feedback: 0.6,
			modDepth: 0.1,
			modFreq: 2.0);
		verb = FreeVerb2.ar(dly[0], dly[1], mix: 0.5, room: 0.6, damp: 0.2, mul: 1.0, add: 0.0);
		Out.ar(outBus, input*(1-mix)+verb*mix);
	}).add;




	SynthDef(\outBusSynth,{
		arg inBus=0, outBus=0, vol=1;
		var input;
		input = In.ar(inBus,2);
		Out.ar(outBus, vol*input);
	}).add;

	// SYNTH INSTANTATION
	{~bass = Synth.newPaused(\bassSynth, [outBus: ~bassBus]);}.defer(0.2);
	{~delayFx = Synth.new(\delay,[inBus:~delayBus]);}.defer(0.2);
	{~bassMaster = Synth.after(~bass,\outBusSynth,[inBus:~bassBus]);}.defer(0.2);
	{~padMaster = Synth.new(\outBusSynth,[inBus:~padBus]);}.defer(0.2);
	{~arpMaster = Synth.new(\outBusSynth,[inBus:~arpBus, outBus:~delayBus]);}.defer(0.2);


	Pdef(\harmony).clear;

	~pad = Pdef(\harmony,
		Pbind(
			\instrument, \padSynth,
			\dur, 4,
			\note, Pdefn(\harm_note, Pseq([1],1)),
			\rel, 4/TempoClock.default.tempo;,
			\amp, Pdefn(\harm_amp, 1)*Pdefn(\padVolume, 1),
			\outBus, ~padBus
		)
	);

	~arp = Pdef(\arpeggiator,
		Pbind(
		\instrument, \arp,
		\note, Pdefn(\arp_note, Pseq([1],1)),
		\dur, Pseq([Prand([~t,~t/2]), Prand([~t,~t/2]), ~t/2], inf),
		\outBus, ~arpBus
		)
	);

	~i=0;
	OSCdef('OSCreceiver',
		{
			arg msg;
			~chordsList = [];
			~chord = msg[1].asString;//String [freq1, freq2, freq3][...][...]

			~oscMsg = ~chord.replace("[", "").replace("]", "").split($:);

			for(0,~oscMsg.size-2,{
				arg i;
				~n1 = ~oscMsg[i].replace(" ", "").split($,);
				for (0,~n1.size-1,{
					arg j, c;
					c = ~n1[j].asInteger;
					~f = ~f.add(c);
				});
				~chordsList = ~chordsList.add(~f);
				if(~pad.isPlaying == false,
					{
						Pdefn(\harm_note, Pseq(~chordsList, inf).asStream);
						Pdefn(\harm_amp, 1/~f.size*~padVolume);
						~pad.play(TempoClock.default, quant:4);
						~isPlaying = true}
				);
				Pdefn(\harm_note, Pseq(~chordsList, inf, ~i).asStream);
				Pdefn(\harm_amp, 1/~f.size);
				~f = [];
				~i=(~i+1)%~chordsList.size;
			});
	}, "/values");


	OSCdef('OSCBass',
		{
			arg msg;
			~bassNote = msg[1].asString;
			~bassNote = ~bassNote.asInteger;
			if(~bassNote>36,{~bassNote=~bassNote-12});

			// CAMBIO DELLA NOTA DI BASSO ALLA QUINTA SOTTO (-5 ST) OGNI 8 BATTUTE PER DUE BATTUTE
			if((TempoClock.default.bar % 8 == 0) || ((TempoClock.default.bar-1) % 8 == 0 ),{
				~rootCounter=0;
				~bassNote=~bassNote-5;});

			~bass.set(\note, ~bassNote, \gate, 1);
			~bass.run(true);
	}, "/bass");

	OSCdef('OSCLead',
		{
			arg msg;
			"msg lead: ".post; msg.postln;
			~lead_list = msg[1].asString.interpret;
			~lead_list2 = (~lead_list+12);
			~notes = (~lead_list++~lead_list2.reverse).scramble;
			Pdefn(\arp_note, Pseq(~notes,1).asStream);
			~arp.play;
	}, "/lead_notes");

	OSCdef('\ExplosionSound',{
		arg msg;
		var attackTime, frameRate, explosionFinished;
		attackTime = msg[1]; // float
		frameRate = msg[2];  // float
		explosionFinished = msg[3]; // boolean
		if(explosionFinished.not,{
			~riser = Synth(\riser, [\gate, 0]);
		});
		~riser.set(\a, attackTime, \framerate, frameRate, \gate, explosionFinished.not.asInteger);
		if(explosionFinished,{
			t = TempoClock.default;
			t.schedAbs(t.nextBar+8,{
				"FREE!".postln;
				~riser.free
			});
		});
		"gate: ".post;
		explosionFinished.not.asInteger.postln;
	}, "/explosion");

	OSCdef('RESET',{
		arg msg;
		s.freeAll;
		CmdPeriod.run;
		msg.postln;
		~main.value;
	},"/reset");

	OSCdef('checkVolume',{
		arg msg;
		~faderName = msg[1];
		~faderVal= msg[2];

		if(~faderName=='Master',{
			// msg.postln;
			~masterVolume.volume = ~faderVal;
		},{});
		if(~faderName=='Bass',{
			~bassMaster.set(\vol, ~faderVal.dbamp);
		},{});
		if(~faderName=='Pad',{
			~padMaster.set(\vol, ~faderVal.dbamp);
		},{});
		if(~faderName=='Arp',{
			~arpMaster.set(\vol, ~faderVal.dbamp);
		},{});

	},"/mixerFader");

	OSCdef('EXIT',{
		Server.killAll;
		0.exit;
	},"/exit");
};

s.waitForBoot({
	postln("CORRECTLY BOOTED! NOW RUN PROCESSING SKATCH!");
	NetAddr.localAddr.postln;
});
s.doWhenBooted(~main);

)

