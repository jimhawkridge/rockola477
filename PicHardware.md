Description of Hardware
=======================

Here is a description of the hardware. You should read [Testing Mechanism Control](MechanismControl.md) first.

My board was constructed in the same form factor as the original board. I removed the connectors from the original board and arranged the new board so that they were in the same places as the old board so the wiring would reach. My unit originally had no coin validation unit so I used the wiring loom that would usually connect to that to connect to the logic board.

Circuit Details
---------------

Power comes from the white connector on the right hand side of the board. Black is ground, red should be 9.6V so that needs converting to 5V for the PIC.

The 7 segment displays and keyboard are both multiplexed. To light a segment you have to pull down both the segment line and the grid line for that digit. I have used ULN2803As to do that but I think that was just because I had them lying around. You need pull up resistors.
The pins on the PIC that drive the ULN2803s also drive the keyboard multiplex directly.

PORTC 0-3 on the PIC are inputs. These are driven from the logic board pins mentioned in MechanismControl via a ULN2003A again with pull ups.  I.e. when one of the logic board pins goes high (9.6V) the PIC gets 0V and when the pin goes low it gets 5V.
PORTD 0 and 1 are outputs. I seem to remember they drive the logic board board directly (via resistors?).

The LEDs are driven directly by the PIC.

I have the serial port (PORTC 6,7) connected for in circut programming.

Pins are connected as follows:

**PORTA**
   * 0: Add credit (this is connected to a simple coin switch on my box.
   * 1-5: Display grids for the 7 segment displays 1 to 5. The keyboard multiplex is also fed from these.

**PORTB**    
   * 0: 7 segment displays segment D
   * 1: Segment C
   * 2: Segment G
   * 3: Pull down for Low Voltage programming mode
   * 4: Segment F
   * 5: Segment E
   * 6: Segment A
   * 7: Segment B

**PORTC**
   * 0: A/B
   * 1: Opto encoder
   * 2: Home
   * 3: Scan lever
   * 4: Button on my PCB that does nothing.
   * 5: LED for debugging!

**PORTD**   
   * 0: Start carousel pin
   * 1: Stop carousel and play pin
   * 2,3: Two more buttons that do nothing!
   * 4: Now playing LED
   * 5: Your selection LED
   * 6: Reset - reselect LED
   * 7: Add coins LED

**PORTE**
   * 1-3: Keyboard multiplex returns.


The circuit could easily be built without a PCB. The PCB just makes it look cooler and allows re-use of the connectors to keep the wiring nice and easy.

Modifications To Other Circuit Boards
-------------------------------------

I half remember that I got the polarity of the keyboard multiplex the wrong way round and had to remove some diodes from the Keyboard PCB. I will verify this.
