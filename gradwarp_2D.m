function img_corr = gradwarp_2D(img, coeff, four_corners)
% Author       : Fred J. Frigo
% Date         : Mar 08, 2026
% img          : Ny x Nx image
% coeff        : gradient harmonic coefficients
% four_corners : 4x3 matrix of (x,y,z) in mm
%
% Performs 2D interpolation for Gradwarp MR image correction 
% Determines gradient coil, orientation, FOV, and slice offset from Pfile

[Ny, Nx] = size(img);

Rnorm = 0.025;   % empirical scaling
tol   = 1e-6;

%% -------------------------------------------------
% 1) Extract geometry
%% -------------------------------------------------

x_vals = four_corners(:,1);
y_vals = four_corners(:,2);
z_vals = four_corners(:,3);

xmin = min(x_vals); xmax = max(x_vals);
ymin = min(y_vals); ymax = max(y_vals);
zmin = min(z_vals); zmax = max(z_vals);

%% -------------------------------------------------
% 2) Detect orientation
%% -------------------------------------------------

if max(abs(y_vals - y_vals(1))) < tol
    orientation = 'coronal';
    slice_pos = y_vals(1);  % constant Y

elseif max(abs(z_vals - z_vals(1))) < tol
    orientation = 'axial';
    slice_pos = z_vals(1);  % constant Z

elseif max(abs(x_vals - x_vals(1))) < tol
    orientation = 'sagittal';
    slice_pos = x_vals(1);  % constant X

else
    error('Cannot determine slice orientation');
end

fprintf('Orientation: %s | Slice position: %.2f mm\n', ...
        orientation, slice_pos);

%% -------------------------------------------------
% 3) Build coordinate grid from geometry
%% -------------------------------------------------

switch orientation

    case 'axial'

        FOVu = xmax - xmin;
        FOVv = ymax - ymin;

        u_mm = linspace(xmax, xmin, Nx);
        v_mm = linspace(ymax, ymin, Ny);

        [Umm, Vmm] = meshgrid(u_mm, v_mm);

        Xmm = Umm;
        Ymm = Vmm;
        Zmm = slice_pos * ones(size(Umm));

        inplane1 = 'X';
        inplane2 = 'Y';

    case 'coronal'

        FOVu = xmax - xmin;
        FOVv = zmax - zmin;

        u_mm = linspace(xmax, xmin, Nx);
        v_mm = linspace(zmax, zmin, Ny);

        [Umm, Vmm] = meshgrid(u_mm, v_mm);

        Xmm = Umm;
        Ymm = slice_pos * ones(size(Umm));
        Zmm = Vmm;

        inplane1 = 'X';
        inplane2 = 'Z';

    case 'sagittal'

        FOVu = ymax - ymin;
        FOVv = zmax - zmin;

        u_mm = linspace(ymax, ymin, Nx);
        v_mm = linspace(zmax, zmin, Ny);

        [Umm, Vmm] = meshgrid(u_mm, v_mm);

        Xmm = slice_pos * ones(size(Umm));
        Ymm = Umm;
        Zmm = Vmm;

        inplane1 = 'Y';
        inplane2 = 'Z';
end

fprintf('FOV_u = %.2f mm | FOV_v = %.2f mm\n', FOVu, FOVv);

%% -------------------------------------------------
% 4) Convert to normalized meters
%% -------------------------------------------------

x = (Xmm / 1000) / Rnorm;
y = (Ymm / 1000) / Rnorm;
z = (Zmm / 1000) / Rnorm;

r2 = x.^2 + y.^2 + z.^2;

%% -------------------------------------------------
% 5) 3D Harmonic displacement
%% -------------------------------------------------

S3x = coeff.X(3);  S5x = coeff.X(5);
S3y = coeff.Y(3);  S5y = coeff.Y(5);
S3z = coeff.Z(3);  S5z = coeff.Z(5);

Dx3 = S3x .* ( (2/3)*x.*(y.^2+z.^2) - (1/3)*x.^3 );
Dy3 = S3y .* ( (2/3)*y.*(x.^2+z.^2) - (1/3)*y.^3 );
Dz3 = S3z .* ( (2/3)*z.*(x.^2+y.^2) - (1/3)*z.^3 );

Dx5 = S5x .* ( ...
      x.*(y.^2+z.^2).^2 ...
    - (6/7)*x.*(y.^2+z.^2).*r2 ...
    + (3/35)*x.*r2.^2 );

Dy5 = S5y .* ( ...
      y.*(x.^2+z.^2).^2 ...
    - (6/7)*y.*(x.^2+z.^2).*r2 ...
    + (3/35)*y.*r2.^2 );

Dz5 = S5z .* ( ...
      z.*(x.^2+y.^2).^2 ...
    - (6/7)*z.*(x.^2+y.^2).*r2 ...
    + (3/35)*z.*r2.^2 );

Dx = (Dx3 + Dx5) * 1000;
Dy = (Dy3 + Dy5) * 1000;
Dz = (Dz3 + Dz5) * 1000;

%% -------------------------------------------------
% 6) Select in-plane displacement
%% -------------------------------------------------

switch inplane1
    case 'X', D1 = Dx;
    case 'Y', D1 = Dy;
    case 'Z', D1 = Dz;
end

switch inplane2
    case 'X', D2 = Dx;
    case 'Y', D2 = Dy;
    case 'Z', D2 = Dz;
end

fprintf('Max in-plane displacement (mm): %.4f\n', ...
        max(sqrt(D1(:).^2 + D2(:).^2)));

%% -------------------------------------------------
% 7) Convert mm → pixel shift
%% -------------------------------------------------

du_pix = FOVu / (Nx - 1);
dv_pix = FOVv / (Ny - 1);

D1_pix = D1 / du_pix;
D2_pix = D2 / dv_pix;

%% -------------------------------------------------
% 8) Backward resampling
%% -------------------------------------------------

[col,row] = meshgrid(1:Nx, 1:Ny);

col_corr = col - D1_pix;
row_corr = row - D2_pix;

img_corr = interp2(col,row,img,col_corr,row_corr,'linear',0);

end