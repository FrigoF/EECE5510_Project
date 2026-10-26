function coeff = read_ge_coeff(gradient_coil_type)
%    Gradient Nonlinearity Image correction
%    Get spherical harmonic correction coefficients
%    The coefficients are in the file "gw_coils.dat"
%
%    Fred J. Frigo   03-Mar-2026
%

coeff.X = zeros(10,1);
coeff.Y = zeros(10,1);
coeff.Z = zeros(10,1);

if (gradient_coil_type == 5) % 50cm BRM coil

   coeff.X(3) = -1.3898295e-4;
   coeff.X(5) = -8.7744000e-8;
   coeff.Y(3) = -1.3409085e-4;
   coeff.Y(5) = -9.0102937e-8;
   coeff.Z(3) = -1.174155e-5;
   coeff.Z(5) = -1.12209e-8;

else if (gradient_coil_type == 0)  % 50cm XRMB coil

   coeff.X(3) = -1.2498e-4;
   coeff.X(5) = -9.7395e-8;
   coeff.Y(3) = -1.0338e-4;
   coeff.Y(5) = -1.0046e-7;
   coeff.Z(3) = -4.8939e-5;
   coeff.Z(5) = -1.63e-8;

end

end