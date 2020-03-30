function md = friction_coefficient_conversion( md, friction_law_in, friction_law_out, varargin )

   p = inputParser;
   addRequired(p, 'md');
   addRequired(p, 'friction_law_in');
   addRequired(p, 'friction_law_out');
   % Budd
   addOptional(p, 'p', []);
   addOptional(p, 'q', []);
   % Weertman / Schoof / Tsai
   addOptional(p, 'C_max', []);
   addOptional(p, 'm', []);

   parse(p, md, friction_law_in, friction_law_out, varargin{:});
   md = p.Results.md;
   p_out = p.Results.p;
   q_out = p.Results.q;
   C_max = p.Results.C_max;
   m = p.Results.m;

   % Initialize output
   if strcmp(friction_law_in, 'budd')
      C_in = md.friction.coefficient;
   elseif strcmp(friction_law_in, 'weertman')
      C_in = md.friction.C;
   end
   C_out = nan * ones(size(C_in));

   % Get some model parameters
   N = effectivepressure(md);
   u_b = sqrt( md.initialization.vx.^2 + md.initialization.vy.^2 ) / md.constants.yts;
   
   if strcmp(friction_law_in, 'budd') & strcmp(friction_law_out, 'budd') %%{{{
      % DENIS
      %[~, ~, tau_b] = basalstress(md);

      % MATHIEU:
      N  = md.constants.g*(md.materials.rho_ice*md.geometry.thickness+md.materials.rho_water*md.geometry.base);
      N(N<0) = 0;
      vb = sqrt(md.results.StressbalanceSolution.Vx.^2+md.results.StressbalanceSolution.Vy.^2)/md.constants.yts;
      taub = md.friction.coefficient.^2.*N.*vb;

      md.friction.p(:) = p_out;
      md.friction.q(:) = q_out;
      md.friction.coefficient = sqrt(taub./max(1,N.^(q_out/p_out) .* vb.^(1/p_out)));
      
      %r_out = averaging(md, q_out ./ p_out, 0);
      %s_out = averaging(md, 1 ./ p_out, 0);
      %C_out = sqrt( tau_b ./ (N.^r_out .* u_b.^s_out) );
      %C_out(isnan(C_out)) = min(C_out);

      % Extrapolate one node %%{{{
      %tau_b_elements = tau_b(md.mesh.elements);
      %mask_elements = md.mask.ice_levelset(md.mesh.elements);
      %idx_nanfill = find(sum(mask_elements<0,2)==1 | sum(mask_elements<0,2)==2);
      %for i = idx_nanfill'
      %   nan_nodes   = md.mesh.elements(i, tau_b_elements(i,:)==0);
      %   valid_nodes = md.mesh.elements(i, tau_b_elements(i,:)~=0);
      %   tau_b(nan_nodes) = mean(tau_b(valid_nodes));
      %end %%}}}
      
      %% Original parameters
      %r_in = averaging(md, md.friction.q ./ md.friction.p, 0);
      %s_in = averaging(md, 1 ./ md.friction.p, 0);

      %% New parameters
      %r_out = averaging(md, q_out ./ p_out, 0);
      %s_out = averaging(md, 1 ./ p_out, 0);
      %C_out = sqrt( C_in.^2 .* abs(u_b).^(s_in-s_out) );
      
      %md.friction.coefficient = C_out;
      %md.friction.p = p_out;
      %md.friction.q = q_out;
   end %%}}}

   if strcmp(friction_law_in, 'weertman') & strcmp(friction_law_out, 'budd') %%{{{
      C_in = md.friction.C;
      m_in = md.friction.m;
      m_avg = averaging(md, m_in, 0);

      r_out = averaging(md, q_out ./ p_out, 0);
      s_out = averaging(md, 1 ./ p_out, 0);
      
      [~, ~, b] = basalstress(md);
      C_out = sqrt(b ./ (N.^r_out .* u_b.^s_out));

      md.friction = friction;
      md.friction.coefficient = C_out;
      md.friction.p = p_out;
      md.friction.q = q_out;
   end %%}}}

   if strcmp(friction_law_in, 'budd') & strcmp(friction_law_out, 'weertman') %%{{{
      % From Mathieu:
      %Assume p = q = 1 in Budd's law
      N  = md.constants.g*(md.materials.rho_ice*md.geometry.thickness+md.materials.rho_water*md.geometry.base);
      N(N<0) = 0;
      vb = sqrt(md.results.StressbalanceSolution.Vx.^2+md.results.StressbalanceSolution.Vy.^2)/md.constants.yts;
      taub = md.friction.coefficient.^2.*N.*vb;
      
      %now translate that to Weertman's law
      md.friction = frictionweertman();
      md.friction.m = m * ones(md.mesh.numberofelements,1);
      %taub = C^(-1/m) * vb^(1/m)
      %so that C = (vb^(1/m)/taub)^m
      md.friction.C = vb .* max(1,taub).^-m;

      %m_avg = averaging(md, m, 0);
      [~, ~, tau_b] = basalstress(md);
   
      % Extrapolate one node %%{{{
      %tau_b_elements = tau_b(md.mesh.elements);
      %mask_elements = md.mask.ice_levelset(md.mesh.elements);
      %idx_nanfill = find(sum(mask_elements<0,2)==1 | sum(mask_elements<0,2)==2);
      %for i = idx_nanfill'
      %   nan_nodes   = md.mesh.elements(i, tau_b_elements(i,:)==0);
      %   valid_nodes = md.mesh.elements(i, tau_b_elements(i,:)~=0);
      %   tau_b(nan_nodes) = mean(tau_b(valid_nodes));
      %end %%}}}

      %C_out = tau_b.^-m .* u_b;
      %C_out(isnan(C_out)) = min(C_out);
      %C_out(C_out==0) = min(C_out(C_out~=0));

      %r = averaging(md, md.friction.q ./ md.friction.p, 0);
      %s = averaging(md, 1 ./ md.friction.p, 0);
      %m_avg = averaging(md, m, 0);
      %C_out = (C_in.^2 .* N).^(-m_avg) .* abs(u_b).^(1-m_avg);

      %md.friction = frictionweertman;
      %md.friction.m = m * ones(md.mesh.numberofelements,1);
      %md.friction.C = C_out;
   end %%}}}

   if strcmp(friction_law_in, 'budd') & strcmp(friction_law_out, 'schoof') %%{{{
      r = averaging(md, md.friction.q ./ md.friction.p, 0);
      s = averaging(md, 1 ./ md.friction.p, 0);
      C_out = ( (C_in.^2 .* N).^(-1./m) .* abs(u_b).^((m-1)./m) - (C_max.*N).^(-1./m) .* abs(u_b) ) .^ -m;
      
      md.friction = frictionschoof;
      md.friction.m = m;
      md.friction.C = C_out;
      md.friction.Cmax = C_max;
   end %%}}}

   if strcmp(friction_law_in, 'budd') & strcmp(friction_law_out, 'tsai') %%{{{
      r = averaging(md, md.friction.q ./ md.friction.p, 0);
      s = averaging(md, 1 ./ md.friction.p, 0);
      C_out = C_in.^2 .* N .* abs(u_b).^(-m);
      f = C_in.^2 .* abs(u_b);
      
      md.friction = frictionschoof;
      md.friction.C = C_out;
      md.friction.f = f;
      md.friction.m = m;
   end %%}}}

end % main function

