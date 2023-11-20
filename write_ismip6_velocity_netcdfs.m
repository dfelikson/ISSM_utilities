function write_ismip6_velocity_netcdfs(md_mesh_elements, md_mesh_x, md_mesh_y, time, vx, vy, output_netcdf_suffix)

   % Unit conversion from ISSM units (m/a) to ISMIP6 units (m/s)
   vx = vx ./ (86400*365);
   vy = vy ./ (86400*365);

   % NOTE: The time epoch is hardcoded and it is assumed that the output is 1/yr at the end of the year.
   epoch_year = 2007;
   % NOTE: The 360_day calendar is also hardcoded.
   % NOTE: For state variables, time_state = [end_of_yr_2014, end_of_yr_2015, ..., end_of_yr_2100]
   time_state = 360 .* (time - epoch_year);

   % ISMIP6 1km grid
   xgrid =  -720000:1000: 960000; % projected x coordinates spaced 1 km apart
   ygrid = -3450000:1000:-570000; % projected y coordinates spaced 1 km apart
   
   % Interpolate velocity fields onto grid
   xvelsurf= zeros(length(ygrid), length(xgrid), length(time_state));
   yvelsurf = zeros(length(ygrid), length(xgrid), length(time_state));
   for j = 1:length(time_state)
       [~, xvelsurf(:,:,j)] = evalc('InterpFromMeshToGrid(md_mesh_elements, md_mesh_x, md_mesh_y, vx(:,j), xgrid, ygrid, NaN);');
       [~, yvelsurf(:,:,j)] = evalc('InterpFromMeshToGrid(md_mesh_elements, md_mesh_x, md_mesh_y, vy(:,j), xgrid, ygrid, NaN);');
   end

   for variable_name_cell = {'xvelsurf', 'yvelsurf'}
      variable_name = variable_name_cell{1};
      output_netcdf_filename = [variable_name '_' output_netcdf_suffix '.nc'];

      % Coordinates and times {{{
      % x
      nccreate(output_netcdf_filename,'x','Dimensions',{'x',length(xgrid)})
      ncwriteatt(output_netcdf_filename,'x','units','m')
      ncwriteatt(output_netcdf_filename,'x','axis','X')
      %ncwriteatt(output_netcdf_filename,'x','standard_name','projection_x_coordinate')
      ncwriteatt(output_netcdf_filename,'x','long_name','Cartesian x-coordinate')
      ncwrite(output_netcdf_filename,'x',xgrid)
   
      % y
      nccreate(output_netcdf_filename,'y','Dimensions',{'y',length(ygrid)})
      ncwriteatt(output_netcdf_filename,'y','units','m')
      ncwriteatt(output_netcdf_filename,'y','axis','Y')
      %ncwriteatt(output_netcdf_filename,'y','standard_name','projection_y_coordinate')
      ncwriteatt(output_netcdf_filename,'x','long_name','Cartesian y-coordinate')
      ncwrite(output_netcdf_filename,'y',ygrid)
      
      % time
      nccreate(output_netcdf_filename,'time','Dimensions',{'time',length(time_state)})
      ncwriteatt(output_netcdf_filename,'time','units',sprintf('days since 01-01-%4d',epoch_year))
      ncwriteatt(output_netcdf_filename,'time','calendar','360_day')
      ncwriteatt(output_netcdf_filename,'time','axis','T')
      ncwriteatt(output_netcdf_filename,'time','long_name','time')
      ncwriteatt(output_netcdf_filename,'time','standard_name','time')
      ncwrite(output_netcdf_filename,'time',time_state)
      %}}}
      % Projection {{{
      nccreate(output_netcdf_filename,'Polar_Stereographic','Datatype','char')
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','ellipsoid','WGS84')
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','false_easting',0.0)
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','false_northing',0.0)
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','grid_mapping_name','polar_stereographic')
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','latitude_of_projection_origin',90.0)
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','standard_parallel',70.0)
      ncwriteatt(output_netcdf_filename,'Polar_Stereographic','straight_vertical_longitude_from_pole',-45.0)
      %}}}
   
      % Velocity
      nccreate(output_netcdf_filename,  variable_name,'FillValue',9.96921e36,'Dimensions',{'y',length(ygrid),'x',length(xgrid),'time',length(time_state)})
      ncwrite(output_netcdf_filename,   variable_name, eval(variable_name))
      ncwriteatt(output_netcdf_filename,variable_name,'grid_mapping','Polar_Stereographic')
      ncwriteatt(output_netcdf_filename,variable_name,'standard_name','land_ice_surface_x_velocity')
      ncwriteatt(output_netcdf_filename,variable_name,'units','m/s')
   
   end

end % main function

