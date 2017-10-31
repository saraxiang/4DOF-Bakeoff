import java.util.ArrayList;
import java.util.Collections;
import processing.core.PApplet;

public class main extends PApplet
{

	// these are variables you should probably leave alone
	int index = 0;
	int trialCount = 8; // this will be set higher for the bakeoff
	float border = 0; // have some padding from the sides
	int trialIndex = 0; // what trial are we on
	int errorCount = 0; // used to keep track of errors
	float errorPenalty = 0.5f; // for every error, add this to mean time
	int startTime = 0; // time starts when the first click is captured
	int finishTime = 0; // records the time of the final click
	boolean userDone = false;

	final int screenPPI = 72; // what is the DPI of the screen you are using
	// you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch.

	// These variables are for my example design. Your input code should modify/replace these!
	float screenTransX = 0;
	float screenTransY = 0;
	float screenRotation = 0;
	float screenZ = 50f;

	private class Target
	{
		float x = 0;
		float y = 0;
		float rotation = 0;
		float z = 0;
	}

	ArrayList<Target> targets = new ArrayList<Target>();

	public float inchesToPixels(float inch)
	{
		return inch * screenPPI;
	}

	public void setup()
	{
		size((int) inchesToPixels(2f), (int) inchesToPixels(3.5f)); // 2x3.5' area -- don't modify this

		rectMode(CENTER);
		textFont(createFont("Arial", inchesToPixels(.3f))); // sets the font to Arial that is .3" tall
		textAlign(CENTER);

		border = inchesToPixels(.2f); // padding of 0.2 inches //don't change this!

		for (int i = 0; i < trialCount; i++) // don't change this!
		{
			Target t = new Target();
			t.x = random(-width / 2 + border, width / 2 - border); // set a random x with some padding
			t.y = random(-height / 2 + border, height / 2 - border);// set a random y with some padding
			t.rotation = random(0, 360); // random rotation between 0 and 360
			int j = (int) random(20);
			t.z = ((j % 20) + 1) * inchesToPixels(.15f); // increasing size from .15 up to 3.0" targets.add(t);
			println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
		}

		Collections.shuffle(targets); // randomize the order of the button;

	}

	public void draw()
	{

		background(80); // background is light grey
		fill(200);
		noStroke();

		// shouldn't really modify this printout code unless there is a really good reason to
		if (userDone)
		{
			text("User completed " + trialCount + " trials", width / 2, inchesToPixels(.2f));
			text("User had " + errorCount + " error(s)", width / 2, inchesToPixels(.2f) * 2);
			text("User took " + (finishTime - startTime) / 1000f / trialCount + " sec per target", width / 2, inchesToPixels(.2f) * 3);
			text("User took " + ((finishTime - startTime) / 1000f / trialCount + (errorCount * errorPenalty)) + " sec per target inc. penalty", width / 2, inchesToPixels(.2f) * 4);

			return;
		}

		// ===========DRAW TARGET SQUARE=================
		pushMatrix();
		translate(width / 2, height / 2); // center the drawing coordinates to the center of the screen
		Target t = targets.get(trialIndex);
		translate(t.x, t.y); // center the drawing coordinates to the center of the screen
		rotate(radians(t.rotation));
		fill(255, 0, 0); // set color to semi translucent
		rect(0, 0, t.z, t.z);
		popMatrix();

		// ===========DRAW CURSOR SQUARE=================
		pushMatrix();
		translate(width / 2, height / 2); // center the drawing coordinates to the center of the screen
		translate(screenTransX, screenTransY);
		rotate(radians(screenRotation));
		noFill();
		strokeWeight(3f);
		stroke(160);
		rect(0, 0, screenZ, screenZ);
		popMatrix();

		// ===========DRAW EXAMPLE CONTROLS=================
		fill(255);
		scaffoldControlLogic(); // you are going to want to replace this!
		text("Trial " + (trialIndex + 1) + " of " + trialCount, width / 2, inchesToPixels(.5f));
	}

	public void scaffoldControlLogic()
	{
		// upper left corner, rotate counterclockwise
		text("CCW", inchesToPixels(.2f), inchesToPixels(.2f));
		if (mousePressed && dist(0, 0, mouseX, mouseY) < inchesToPixels(.5f))
			screenRotation--;

		// upper right corner, rotate clockwise
		text("CW", width - inchesToPixels(.2f), inchesToPixels(.2f));
		if (mousePressed && dist(width, 0, mouseX, mouseY) < inchesToPixels(.5f))
			screenRotation++;

		// lower left corner, decrease Z
		text("-", inchesToPixels(.2f), height - inchesToPixels(.2f));
		if (mousePressed && dist(0, height, mouseX, mouseY) < inchesToPixels(.5f))
			screenZ -= inchesToPixels(.02f);

		// lower right corner, increase Z
		text("+", width - inchesToPixels(.2f), height - inchesToPixels(.2f));
		if (mousePressed && dist(width, height, mouseX, mouseY) < inchesToPixels(.5f))
			screenZ += inchesToPixels(.02f);

		// left middle, move left
		text("left", inchesToPixels(.2f), height / 2);
		if (mousePressed && dist(0, height / 2, mouseX, mouseY) < inchesToPixels(.5f))
			screenTransX -= inchesToPixels(.02f);

		text("right", width - inchesToPixels(.2f), height / 2);
		if (mousePressed && dist(width, height / 2, mouseX, mouseY) < inchesToPixels(.5f))
			screenTransX += inchesToPixels(.02f);

		text("up", width / 2, inchesToPixels(.2f));
		if (mousePressed && dist(width / 2, 0, mouseX, mouseY) < inchesToPixels(.5f))
			screenTransY -= inchesToPixels(.02f);

		text("down", width / 2, height - inchesToPixels(.2f));
		if (mousePressed && dist(width / 2, height, mouseX, mouseY) < inchesToPixels(.5f))
			screenTransY += inchesToPixels(.02f);
	}

	public void mousePressed()
	{
		if (startTime == 0) // start time on the instant of the first user action
		{
			startTime = millis();
			println("time started!");
		}
	}

	public void mouseReleased()
	{
		// check to see if user clicked middle of screen within 3 inches
		if (dist(width / 2, height / 2, mouseX, mouseY) < inchesToPixels(3f))
		{
			if (userDone == false && !checkForSuccess())
				errorCount++;

			// and move on to next trial
			trialIndex++;

			if (trialIndex == trialCount && userDone == false)
			{
				userDone = true;
				finishTime = millis();
			}
		}
	}

	// probably shouldn't modify this, but email me if you want to for some good reason.
	public boolean checkForSuccess()
	{
		Target t = targets.get(trialIndex);
		boolean closeDist = dist(t.x, t.y, -screenTransX, -screenTransY) < inchesToPixels(.05f); // has to be within .1"
		boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation, screenRotation) <= 5;
		boolean closeZ = abs(t.z - screenZ) < inchesToPixels(.05f); // has to be within .1"
		println("Close Enough Distance: " + closeDist);
		println("Close Enough Rotation: " + closeRotation + "(dist=" + calculateDifferenceBetweenAngles(t.rotation, screenRotation) + ")");
		println("Close Enough Z: " + closeZ);
		return closeDist && closeRotation && closeZ;
	}

	double calculateDifferenceBetweenAngles(float a1, float a2)
	{
		double diff = abs(a1 - a2);
		diff %= 90;
		if (diff > 45)
			return 90 - diff;
		else
			return diff;
	}
}
