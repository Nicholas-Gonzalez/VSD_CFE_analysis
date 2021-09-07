// Setup variables
//getDimensions(w, h, channels, slices, frames);
getDimensions(w, h, channels, slices, frames);
//w = 256;
//h = 256;

// generate dummy image used by ROI manager
newImage("temp image for RoiSet_to_det.ijm", "8-bit", w, h, 0);  
ID = getImageID();

// count number of ROIs or ask for RoiSet file if no ROI is defined
n_ROI = roiManager("count");
if (n_ROI == 0) {
	path = File.openDialog("Choose RoiSet zip file.");
	roiManager("open", path);
	n_ROI = roiManager("count");
}
	
// generate the body of det file
str = "";
for (n = 0; n < n_ROI; n++) {
	updateDisplay();
	roiManager("select", n);
	for (y = 0; y < h; y++) {
		for (x = 0; x < w; x++) {
			i = y*w + x + 1;  // this was incorrect, should be *w not *h it would only be erroneous if x and y are not equal// convert x-y coordinate to detector index (index is 1 at the top-left corner)
			if (Roi.contains(x,y)) {
				str = str + d2s(i,0) + "\r\n";
				setPixel(x, y, 100+n);// sanity check when w ~= h
			}
			
		}
	}
	str = str + ",\r\n";
}

// close dummy image
selectImage(ID);
close(); 

// display the body of det file in a text window
showText("kernel.det", str);


