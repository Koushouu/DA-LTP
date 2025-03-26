clear all;
N_inp = 10;
N_out = 10;
N_instructive = 10;
N_supervised = 10;
N_readout = 10;
T= 2500;
Tinp = 1000;
Tinphalf = 500;
Tdop = T - Tinp;
inp_rate = 0.02;
instructive_rate = 0.5;
supervised_rate = 0.06;
threshold = 0.4*ones(N_out,1);
threshold_caseC = 0.25;
intrinc = 0.06;
tau_v = 10;
alpha_w = 0.0002;
alpha_w_standRL = alpha_w/50;
alpha_LTD = alpha_w/500;
tau_burst = 5;
burst_threshold = 1.1;
tau_stdp = 10;
tau_elgigbility = 10*60*1000;
tau_inb_trace = 50;
Total_trail = 2;

for trail = 1:Total_trail
    weight = ones (N_inp,N_out)/N_inp;
    weight_p = weight*0;
    weight_m = weight*0;
    weight_instructive = eye(N_instructive,N_out)/N_instructive;
    weight_supervised = eye(N_instructive,N_out);
    weight_readout = eye(N_instructive,N_out)/N_supervised;
    weight_inhibiton = ones (N_inp,N_out)/N_inp;
    idx = logical(eye(size(weight_inhibiton)));
    weight_inhibiton(idx)= 0;
    volt = zeros(N_out,T);
    spike = zeros(N_out,T);
    volt_readout = zeros(N_out,T);
    inputs_readout = zeros(N_out,T);
    inputs_readout_trace = zeros(N_out,T);
    burst = zeros(N_out,T);
    x_pre = zeros (N_inp,1);
    x_post = zeros (N_out,1);
    prepost = zeros (N_inp,N_out);
    elgigiblity= zeros (N_inp,N_out);
    dopamine = zeros(1,T);
    inputs_instructive = zeros(N_instructive, T);
    inputs_supervised = zeros(N_supervised, T);
    inputs = zeros(N_inp,T);
    intrinc_current = zeros(N_inp,T);
    inputs_instructive(3,Tdop+1:T-Tinphalf) = rand(1,Tinphalf)<instructive_rate;
    inputs_instructive(6,Tdop+Tinphalf+1:T) = rand(1,Tinphalf)<instructive_rate;
    dopamine(1,Tdop+1:T) = ones(1,T-Tdop);
    inputs(:,1:Tinp) = rand(N_inp,Tinp)<inp_rate;
    
    for t = 2:T-1
        volt(:,t+1) = (1-1/tau_v)*volt(:,t) + weight'*inputs(:,t) +weight_instructive'*inputs_instructive(:,t)+weight_supervised'*inputs_readout(:,t-1)+intrinc_current(:,t);
        ind_spikes = find(volt(:,t+1)>threshold);
        spike(ind_spikes,t) = 1;
        volt(ind_spikes,t+1) = 0;

        volt_readout(:,t+1) = (1-1/tau_v)*volt_readout(:,t) + weight_readout'*spike(:,t)+inputs_supervised(:,t)-weight_inhibiton'*inputs_readout_trace(:,t-1);
        ind_spikes_readout = find(volt_readout(:,t+1)>threshold);
        inputs_readout(ind_spikes_readout,t) = 1;
        inputs_readout_trace = (1-1/tau_inb_trace)*inputs_readout_trace + inputs_readout(:,t);
        volt_readout(ind_spikes_readout,t+1) = 0;

        burst(:,t+1) = (1-1/tau_burst)*burst(:,t) + spike(:,t);
        x_pre  = (1-1/tau_stdp)*x_pre + inputs(:,t);
        x_post  = (1-1/tau_stdp)*x_post + spike(:,t);
        prepost = x_pre *x_post';
        elgigiblity = (1-1/tau_elgigbility)*elgigiblity + prepost;
        weight_p = weight_p + alpha_w*dopamine(t)*(ones(N_inp,1).*(burst(:,t)>burst_threshold)').*elgigiblity;
        weight_m = weight_m - alpha_LTD*elgigiblity;
    end
end

image(elgigiblity, "CDataMapping", 'scaled')