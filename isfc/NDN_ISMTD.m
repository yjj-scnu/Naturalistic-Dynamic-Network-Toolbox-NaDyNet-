function dFC_result = NDN_ISMTD(inputdir, savedDir, params, app)
%FORMAT NDN_ISMTD(inputdir, savedDir, params, app)
%MTD generate the products of first-order temporal derivatives for two
% univariate time series divided by products of the standard deviations
% of the two univariate time series. And ISMTD is an improved version of
% MTD. It perfrom a higher spatiotemporal consistency
% 
%
%INPUT:
% inputdir          - Path of nSubjects' 2D ROI timecourse mat/txt file(nT * nR)
% savedDir          - Path for saved
% params            - A structure containing relevant parameters of ISSWFC
%   methodType      - Valid values are 'MTD' or 'ISMTD'. ISMTD is an
%                     improved approach which can accomplish a higher
%                     spatiotemporal consistency.When selecting the
%                     original version, the ISA-type value does not need to
%                     be specified
%                     
%   ISA_type        - Valid values are 'regressLOO' or 'LOO'. The type of
%                     intersubject analysis. 
%   MTDwsize        - A number Type, default is 5
% app               - A optional argument, is a uiobject

if ~isfield(params, "methodType")
    error("params.methodType should not be empty, it must be assgind ")
else
    methodType = params.methodType;
end

if isequal(methodType, 'ISMTD') && ~isfield(params, "ISA_type")
    error("params.methodType should not be empty, it must be assgind ")
end

if isequal(methodType, 'ISMTD') && isfield(params, "ISA_type")
    ISA_type = params.ISA_type;
end

if ~isfield(params, "MTDwsize")
    error("params.MTDwsize should not be empty, it must be assgind ")
else
    MTDwsize = params.MTDwsize;
end


if ~exist("savedDir", "dir")
        mkdir(savedDir)
end

data=read_2Dmat_2_3DmatrixROITC(inputdir);
N_sub = size(data, 3);
N_time = size(data, 1);
N_roi = size(data, 2);

Nwin = N_time;
% MTDwsize=5;

%%
if nargin == 4
    app.ax.Title.String = ['Calculating ' methodType ' ...'];
    app.ax.Color = [0.9375, 0.9375, 0.3375];
    ph = patch(app.ax,[0, 0, 0, 0], [0, 0, 1, 1], [0.6745, 1, 0.8045]);
end
dFC_result=[];
for s=1:N_sub
    subtc=squeeze(data(:,:,s));%time * ROI

    if isequal(methodType, 'ISMTD') % isxxx
        LOO=data;
        LOO(:,:,s)=[];
        fprintf('ISMTD for sub %s\n', num2str(s));

        if isequal(ISA_type, "LOO")

            subtc2=[subtc,squeeze(mean(LOO,3))];
            subtc2Z=zscore(subtc2);
            Ct2 = coupling(subtc2Z, MTDwsize);
            % extract the upper right ISDCC values
            ISCt2=Ct2(1:N_roi, N_roi + 1 : N_roi * 2, :);

            % moving average DCC with window length
            tmp_dFC_DCCX=zeros(Nwin,N_roi*N_roi);
            for iw=1:Nwin
                tmpr=ISCt2(:,:,iw);
                tmp_dFC_DCCX(iw,:)=mat2vec_Asym(tmpr);
            end
        end
        if isequal(ISA_type, "regressLOO")
            LOO_mean = mean(LOO,3);
            subDataAfterRemoveCov = NDN_regressLOO(subtc, LOO_mean);
            subtcZ=zscore(subDataAfterRemoveCov);
            Ct2 = coupling(subtcZ, MTDwsize);
            % extract the upper right ISDCC values
            % moving average DCC with window length
            atmp = zeros(size(Ct2,1),size(Ct2,1));
            tmp_dFC_DCCX = zeros(Nwin,length(mat2vec(atmp)));
            for iw = 1:Nwin
                tmpr = Ct2(:,:,iw);
                tmp_dFC_DCCX(iw,:) = mat2vec(squeeze(tmpr));
            end
        end
    end
    if isequal(methodType, 'MTD')% xxx
        subtcZ=zscore(subtc);%time * ROI
        fprintf('MTD for sub %s\n', num2str(s));

        Ct2 = coupling(subtcZ, MTDwsize);
        % extract the upper right ISDCC values
        % moving average DCC with window length
        atmp = zeros(size(Ct2,1),size(Ct2,1));
        tmp_dFC_DCCX = zeros(Nwin,length(mat2vec(atmp)));
        for iw = 1:Nwin
            tmpr = Ct2(:,:,iw);
            tmp_dFC_DCCX(iw,:) = mat2vec(squeeze(tmpr));
        end

    end

    tmp_dFC=tmp_dFC_DCCX;
    DEV = std(tmp_dFC, [], 2);%STD OF NODE
    [xmax, imax, xmin, imin] = icatb_extrema(DEV);%local maxima in FC variance
    pIND = sort(imax);%?
    k1_peaks(s) = length(pIND);%?
    SP{s,1} = tmp_dFC(pIND, :);%Subsampling
    dFC_result=[dFC_result; tmp_dFC];

    if nargin == 4
        ph.XData = [0, s / N_sub, s / N_sub, 0];
        jindu = sprintf('%.2f',s / N_sub * 100);
        app.ax.Title.String =[ 'Calculating ' methodType ' ' jindu '%...'];
        drawnow
    end
end%s

cd(savedDir)
if exist("ISA_type","var")
    save([methodType '_' ISA_type '_SP.mat'], 'SP', '-v7.3')
    save([methodType '_' ISA_type '_dFC_result.mat'], 'dFC_result', '-v7.3')
else
    save([methodType '_SP.mat'], 'SP', '-v7.3')
    save([methodType '_dFC_result.mat'], 'dFC_result', '-v7.3')
end



end

