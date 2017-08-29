Testing Mechanism Control
-------------------------

If you take the big IC out of the logic board you should be able to control the Juke by connecting voltage to the correct pins and you should be able to read the state of the mechanism from other pins. This is how we control the box.

Pin 15 is power and 21 is ground. The other relevant pins are:

**Inputs**
  * 1: A/B. This goes high on alternate revolutions of the carousel and tells you if you will get side A or B of the record.
  * 3: Home. The carousel is in the home position.
  * 4: The output from the opto encoder on the carousel.
  * 26: Scan lever. (I.e. rotate the carousel for loading records).

**Outputs**
  * 20: Start the carousel rotating.
  * 19: Stop the carousel at the current position and play the record.

**So the operational sequence goes like this**
  * Wait for the home signal.
  * Take pin 20 high until the home signal clears.
  * Count pulses on pin 4 until the correct record is reached.
  * Pulse pin 19.

If pin 1 is signalling A (I forget whether this is high or low) and you wanted B then you just go round again.

Check out the [Description of Hardware](PicHardware.md) page to see how this is controlled from the PIC.
