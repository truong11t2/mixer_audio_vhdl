# mixer_audio_vhdl

Implement an audio mixer with VHDL with the following description

• 4 input channels from a TDM stream, 16 bit samples
• 2 output channels to a TDM stream, 24 bit samples
• every input channel is multiplied with different gain factors for each target channel, gain factors are 10 bit numbers
• every target channel is a sum of weighted input channels
    • with additional master volume control
• for simulation:
    • VHDL-testbench and Design under Test in different modules
    • sample waveforms from files (e.g. .wav file), is generated with Octave
• for synthesis: limit total number of multiplier-instances to 2

The signal flow is illustrated as below.

![alt text](https://github.com/truong11t2/mixer_audio_vhdl/blob/serial_in_out/signalFlow.JPG)
