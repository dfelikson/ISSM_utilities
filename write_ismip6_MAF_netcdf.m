function write_ismip6_MAF_netcdf(time, MAF, output_netcdf_suffix)

   output_netcdf_filename = ['limnsw_' output_netcdf_suffix '.nc'];

   % NOTE: The time epoch is hardcoded and it is assumed that the output is 1/yr at the end of the year.
   epoch_year = 2007;
   % NOTE: The 360_day calendar is also hardcoded.
   % NOTE: For state variables, time_state = [end_of_yr_2014, end_of_yr_2015, ..., end_of_yr_2100]
   time_state = 360 .* (time - epoch_year);

   % time
   nccreate(output_netcdf_filename,'time','Dimensions',{'time',length(time_state)})
   ncwriteatt(output_netcdf_filename,'time','units',sprintf('days since 01-01-%4d',epoch_year))
   ncwriteatt(output_netcdf_filename,'time','calendar','360_day')
   ncwriteatt(output_netcdf_filename,'time','axis','T')
   ncwriteatt(output_netcdf_filename,'time','long_name','time')
   ncwriteatt(output_netcdf_filename,'time','standard_name','time')
   ncwrite(output_netcdf_filename,'time',time_state)

   % MAF
   nccreate(output_netcdf_filename,  'limnsw','FillValue',9.96921e36,'Dimensions',{'time',length(time_state)})
   ncwriteatt(output_netcdf_filename,'limnsw','grid_mapping','Polar_Stereographic')
   ncwriteatt(output_netcdf_filename,'limnsw','standard_name','land_ice_mass_not_displacing_sea_water')
   ncwriteatt(output_netcdf_filename,'limnsw','units','kg')
   ncwrite(output_netcdf_filename,   'limnsw', MAF)

end % main function

