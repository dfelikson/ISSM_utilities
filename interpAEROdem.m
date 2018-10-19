function sout = interpAEROdem(X,Y),

switch oshostname(),
	case {'localhost'}
		if exist(['DEMs/' evalin('base','glacier') '.tif'],'file')
         DEMpath = ['DEMs/' evalin('base','glacier') '.tif'];
      else
         DEMpath='/Users/denisfelikson/Research/Projects/CentralWestGrISGlaciers/Data/AERO_DEMs/05-28-2015/aerodem_1985_1_utm22_polarStereo.tif';
         fprintf(['\n\033[' '103;30' 'm   WARNING: ' 'DEMs/' evalin('base','glacier') '.tif not found; defaulting to: ' DEMpath '\033[0m \n\n']);
      end
	case {'melt.ig.utexas.edu'}
		DEMpath='/disk/staff/gcatania/polar/Arctic/data/AERO_DEM/05-10-2016/aerodem_1985_utm22_1_polarstereo.tif';
	otherwise
		error('machine not supported yet');
end

usemap = 1;
if license('test','map_toolbox')==0,
	disp('WARNING: map toolbox not installed, trying house code');
	usemap = 0;
elseif license('checkout','map_toolbox')==0
	disp('WARNING: map toolbox not available (checkout failed), trying house code');
	usemap = 0;
end

if usemap,
	[data,R] = geotiffread(DEMpath);
	data=double(flipud(data));
	xdata=R.XLimWorld(1):R.DeltaX:R.XLimWorld(2); xdata=xdata(:);
	xdata =(xdata(1:end-1)+xdata(2:end))/2;
	ydata=R.YLimWorld(2):R.DeltaY:R.YLimWorld(1); ydata=flipud(ydata(:));
	ydata =(ydata(1:end-1)+ydata(2:end))/2;
else

	%Get image info
	Tinfo = imfinfo(DEMpath);
	N     = Tinfo.Width;
	M     = Tinfo.Height;
	dx    = Tinfo.ModelPixelScaleTag(1);
	dy    = Tinfo.ModelPixelScaleTag(2);
	minx  = Tinfo.ModelTiepointTag(4);
	maxy  = Tinfo.ModelTiepointTag(5);

	%Generate vectors
	xdata = minx + dx/2 + ((0:N-1).*dx);
	ydata = maxy - dy/2 - ((M  -1:-1:0).*dy);

	%Read image
	data=double(flipud(imread(DEMpath)));
end

% Delete all possible nodata values
data(data == -9999) = nan;
data(data == -3.4028234663852886e+38) = nan;

surf = InterpFromGrid(xdata,ydata,data,X,Y);
surf(surf == -9999) = nan;

% Must reference AERO dem to geoid
geoid = interpGeoid(X,Y);
sout = surf - geoid;

