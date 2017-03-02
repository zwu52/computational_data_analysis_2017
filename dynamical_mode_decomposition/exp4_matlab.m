clear all, close all, clc

t = linspace(0,100);
t_total = 4; %4 seconds clip

dt =  t_total/length(t);
NUM_FRAMES = 100;
RESOLUTION_X = 320;
RESOLUTION_Y = 240;
NUM_PIXELS = RESOLUTION_X * RESOLUTION_Y;


% Load *.mat file generated from python script
X = load('X.mat');   X  = double(X.X);
X1 = load('X1.mat'); X1 = double(X1.X1); %Load -> Convert(
X2 = load('X2.mat'); X2 = double(X2.X2); %...Single->double)

% X1 = X1(50:99,:); %Examine the second half of the video...
% X2 = X2(50:99,:); %...  (more movement)

%% PCA Analsyis && DMD Transformation
[U,Sigma,V] = svd(X1,'econ');
%Step1: Plot Singular Values
figure(1)
plot(abs(diag(Sigma))/sum(abs(diag(Sigma)))*100,'ro')
xlabel('modes')
ylabel('singular values (%)')

title('Singular Values: X1 (%)')
saveas(gcf,'singularValues_percent.png')



%%
% Sample Space => DMD Space: created using combition Fourier/PCA Modes
Stilda = U'*X2*V/Sigma;
% Stilda = U'*X2*V*pinv(Sigma);
Stilda_L1 = U'*X2*V*pinv(Sigma);

logical_L1_L2 = Stilda==Stilda_L1;
percent_same= sum(sum(logical_L1_L2)) / numel(logical_L1_L2);


[W,D] = eig(Stilda); % W: Eigenvalues; D: Eigenvectors

Phi = U*W;%DMD Modes (i.e. DMD Eigenvectors)
Lambda = diag(D); %
Omega = log(Lambda)/dt; %Fourier DMD Space Eigen Values
%% Low-Rank Calculation: degree of trunction: 1,10,20,50
% file_mode1 = 'mat_results_mode1';
% file_mode10 = 'mat_results_mode10';
% file_mode20 = 'mat_results_mode20';
% file_mode50 = 'mat_results_mode50';

file_mode2 = 'mat_results_mode2';
file_mode10 = 'mat_results_mode10';
file_mode20 = 'mat_results_mode20';
file_mode50 = 'mat_results_mode50';

for r = [2 10 20 50]
    U_lr = U(:,1:r);
    Sigma_lr = Sigma(1:r,1:r);
    V_lr = V(:,1:r);
    
    % Low Rank Sample Space => Low Rank  DMD Space
    Stilda_lr = U_lr'*X2*V_lr/Sigma_lr;
    [W_lr,D_lr] = eig(Stilda_lr);
    Phi = U_lr*W_lr;
    Lambda = diag(D_lr);
    Omega = log(Lambda)/dt;
    
    x0 = X1(:,2); % IC (start from frame 2)
    y0 = Phi\X1; % IC in DMD spaces
    
    thres = 1;
    ind_lr = abs(Omega) <= thres;
    keep_percent = sum(sum(ind_lr))/numel(Omega)
    Omega_lr = Omega.*ind_lr;
    
    u_modes = zeros(r,NUM_PIXELS,length(t));
    u_modes_lr = zeros(r,NUM_PIXELS,length(t));
    
    for iter = 1:length(t)
        u_modes(:,:,iter) = (y0.*exp(Omega*t(iter)));
        u_modes_lr(:,:,iter) = (y0.*exp(Omega_lr*t(iter)));
    end
    
    X_dmd = Phi * u_modes(:,:,100);
    X_dmd_lr = Phi * u_modes_lr(:,:,100);
    X_spa = X1 - abs(X_dmd_lr);
   
    %Dealing with Complex/Negative Pixel Intensity
    ind = X_spa<0;
    R = X_spa.*ind; %Residule Matrix
    X_spa = X_spa - R;
    X_dmd_lr = abs(X_dmd_lr) + R;
    
    %Saving Options:
    if r==2
        save(file_mode2,'X_spa','X_dmd_lr','Lambda','keep_percent')
    end
    
    if r==10
        save(file_mode10,'X_spa','X_dmd_lr','Lambda','keep_percent')
    end
    
    if r==20
        save(file_mode20,'X_spa','X_dmd_lr','Lambda','keep_percent')
    end
    
    if r==50
        save(file_mode50,'X_spa','X_dmd_lr','Lambda','keep_percent')
    end
end

%%
load(