function [stranded_nodes clean_mask_or_levelset] = check_levelset_plots(md, option, stranded_nodes)

   switch option
      % Initial level set
      case 'ice_levelset'
         plotmodel(md, 'data', md.mask.ice_levelset, 'edgecolor', 'k', 'figure', 1);
         if ~exist('stranded_nodes','var')
            [stranded_nodes clean_mask_or_levelset] = remove_stranded_ice_spclevelset(md,'ice_levelset');
         end
         hold on
         pos = find(stranded_nodes);
         plot(md.mesh.x(pos), md.mesh.y(pos), 'g.', 'markersize', 40);


      % spclevelsets
      case 'spclevelset'
         if ~exist('stranded_nodes','var')
            [stranded_nodes clean_mask_or_levelset] = remove_stranded_ice_spclevelset(md,'spclevelset');
         end
         idx = find( sum(stranded_nodes) > 0);
         fig_num = 1;
         for i = idx
            plotmodel(md, 'data', md.levelset.spclevelset(1:end-1,i), 'edgecolor', 'k', ...
               'title', ['time = ' sprintf('%4.1f',md.levelset.spclevelset(end,i))], ...
               'figure', fig_num);
            hold on
            pos = find(stranded_nodes(:,i) > 0);
            plot(md.mesh.x(pos), md.mesh.y(pos), 'g.', 'markersize', 40);
            fig_num = fig_num + 1;
         end
   end

end % main function

