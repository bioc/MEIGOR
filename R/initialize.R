#' @include calculate_posterior.R
#' 
#' @title Initialization
#' 
#' @description Initialize internal state from the options set.
#' 
#' 
#' @param options: list with entries as explained below. 
#'    Options set -- defines the problem and sets some
#'    parameters to control the MCMC algorithm.
#' @param model: List of model parameters - to estimate. 
#'    The parameter objects must each have a
#'    'value' attribute containing the parameter's numerical value.
#' @param estimate_params: list. 
#'    List of parameters to estimate, all of which must also be listed
#'    in 'options$model$parameters'.
#' @param initial_values: list of float, optional. 
#'    Starting values for parameters to estimate. If omitted, will use
#'    the nominal values from 'options$model$parameters'
#' @param step_fn: callable f(output), optional. 
#'    User callback, called on every MCMC iteration.
#' @param likelihood_fn: callable f(output, position). 
#'    User likelihood function.
#' @param prior_fn: callable f(output, position), optional. 
#'    User prior function. If omitted, a flat prior will be used.
#' @param nsteps: int. 
#'    Number of MCMC iterations to perform.
#' @param use_hessian: logical, optional. 
#'    Wheter to use the Hessian to guide the walk. Defaults to FALSE.
#' @param rtol: float or list of float, optional. 
#'    Relative tolerance for ode solver.
#' @param atol: float or list of float, optional. 
#'    Absolute tolerance for ode solver.    
#' @param norm_step_size: float, optional. 
#'    MCMC step size. Defaults to a reasonable value.
#' @param hessian_period: int, optional. 
#'    Number of MCMC steps between Hessian recalculations. Defaults
#'    to a reasonable but fairly large value, as Hessian calculation is expensive.
#' @param hessian_scale: float, optional. 
#'    Scaling factor used in generating Hessian-guided steps. Defaults to a
#'    reasonable value.
#' @param sigma_adj_interval: int, optional. 
#'    How often to adjust 'output$sig_value' while annealing to meet
#'    'accept_rate_target'. Defaults to a reasonable value.
#' @param anneal_length: int, optional. 
#'    Length of initial "burn-in" annealing period. Defaults to 10% of
#'    'nsteps', or if 'use_hessian' is TRUE, to 'hessian_period' (i.e. 
#'    anneal until first hessian is calculated)
#' @param T_init: float, optional. 
#'    Initial temperature for annealing. Defaults to a resonable value.
#' @param accept_rate_target: float, optional. 
#'    Desired acceptance rate during annealing. Defaults to a reasonable value.
#'    See also 'sigma_adj_interval' above.
#' @param sigma_max: float, optional. 
#'    Maximum value for 'output$sig_value'. Defaults to a resonable value.
#' @param sigma_min: float, optional. 
#'    Minimum value for 'output$sig_value'. Defaults to a resonable value. 
#' @param sigma_step: float, optional. 
#'    Increment for 'output$sig_value' adjustments. Defaults to a resonable 
#'    value. To eliminate adaptive step size, set sigma_step to 1.
#' @param thermo_temp: float in the range [0,1], optional. 
#'    Temperature for thermodynamic integration support. Used to scale
#'    likelihood when calculating the posterior value. Defaults to 1,
#'    i.e. no effect.
#' 
#' 
#' @param output: List of output values with entries as explained below. 
#' @param num_estimate: int. 
#'    Number of parameters to estimate.
#' @param estimate_idx: list of int.  
#'    Indices of parameters to estimate in the model's full parameter list.
#' @param initial_values: list of float.  
#'    Starting values for parameters to estimate, taken from the parameters'
#'    nominal values in the model or explicitly specified in 'options'.
#' @param initial_position: list of float. 
#'    Starting position of the MCMC walk in parameter space (log10 of 'initial_values').
#' @param position: list of float. 
#'    Current position of MCMC walk in parameter space, i.e. the most
#'    recently accepted move.
#' @param test_position: list of float. 
#'    Proposed MCMC mmove.
#' @param acceptance: int. 
#'    Number of accepted moves.
#' @param T: float.  
#'    Current value of the simulated annealing temperature.
#' @param T_decay: float.  
#'    Constant for exponential decay of 'T', automatically calculated such 
#'    that T will decay from 'options$T_init' down to 1 over the first
#'    'options$anneal_length' setps.
#' @param sig_value: float.  
#'    Current value of sigma, the scaling factor for the proposal distribution.
#'    The MCMC algorithm dynamically tunes this to maintain the aaceptance
#'    rate specified in 'options$accept_rate_target'.
#' @param iter: int.  
#'    Current MCMC step number.
#' @param start_iter: int.  
#'    Starting MCMC step number.
#' @param ode_options: list.  
#'    Options for the ODE integrator, currently just 'rtol' for relative
#'    tolerance and 'atol' for absolute tolerance.
#' @param initial_prior: float. 
#'    Starting prior value, i.e. the value at 'initial_position'.
#' @param initial_likelihood: float.  
#'    Starting likelihood value, i.e. the value at 'initial_position'.
#' @param initial_posterior: float.  
#'    Starting posterior value, i.e. the value at 'initial_position'.
#' @param accept_prior: float.  
#'    Current prior value i.e. the value at 'position'.
#' @param accept_likelihood: float.  
#'    Current likelihood value i.e. the value at 'position'.
#' @param accept_posterior: float.  
#'    Current posterior value i.e. the value at 'position'.
#' @param test_prior: float.  
#'    Prior value at 'test_position'.
#' @param test_likelihood: float.  
#'    Likelihood value at 'test_position'.
#' @param test_posterior: float.  
#'    Posterior value at 'test_position'.
#' @param hessian: array of float. 
#'    Current hessian of the posterior landscape. Size is 
#'    'num_estimate' x 'num_estimate'.
#' @param positions: array of float.  
#'    Trace of all proposed moves. Size is 'num_estimate' x 'nsteps'.
#' @param priors: array of float. 
#'    Trace of all priors corresponding to 'positions'. Length is 'nsteps'.
#' @param likelihoods: array of float. 
#'    Trace of all likelihoods corresponding to 'positions'. Length is 'nsteps'.
#' @param posteriors: array of float. 
#'    Trace of all posteriors corresponding to 'positions'. Length is 'nsteps'.
#' @param alphas: array of float. Trace of 'alpha' parameter and calculated values. Length is 'nsteps'.
#' @param sigmas: array of float. Trace of 'sigma' parameter and calculated values. Length is 'nsteps'.
#' @param delta_posteriors: array of float. Trace of 'delta_posterior' parameter and calculated values. Length is 'nsteps'.
#' @param ts: array of float. Trace of 'T' parameter and calculated values. Length is 'nsteps'.
#' @param accepts: logical array. 
#'    Trace of wheter each proposed move was accepted or not.
#'    Length is 'nsteps'.
#' @param rejects: logical array. Trace of wheter each proposed move was rejected or not. Length is 'nsteps'.
#' @param hessians: array of float. 
#'    Trace of all hessians. Size is 'num_estimate' x 'num_estimate' x 'num_hessians'
#'    where 'num_hessians' is the actual number of hessians to be calculated.
#' 
#' 
#' 
#' 
#' @return Initialized 'output' list.
#' 
initialize = function(output,options){
  # create list of starting values from initial parameter values given by user.
  # vector only contains values which are to be estimated.
  output$num_estimate = length(options$estimate_params)
  if (!is.null(options$initial_values)){
    output$initial_values = options$initial_values
  } else {
    # if no explicit values given, take values from model
    output$initial_values = options$estimate_params
  }
  
  # indices of parameters to be estimated
  output$estimate_idx = match(options$model$parameters$value, options$estimate_params)
  
  # we actually work in a log-transformed phase space
  output$initial_position = log10(output$initial_values)
  output$position = output$initial_position
  
  # create ode_options vector with ode_options[1]=rtol, ode_options[2]=atol
  output$ode_options = list()
  if (!is.null(options$rtol)){
    output$ode_options$rtol = options$rtol
  }
  if (!is.null(options$atol)){
    output$ode_options$atol = options$atol
  }
  output$initial_posterior = calculate_posterior(output,options,output$initial_position)[1]
  output$initial_prior = calculate_posterior(output,options,output$initial_position)[2]
  output$initial_likelihood = calculate_posterior(output,options,output$initial_position)[3]
  
  output$accept_prior = output$initial_prior
  output$accept_likelihood = output$initial_likelihood
  output$accept_posterior = output$initial_posterior
  
  # if anneal length is 0, T_decay is irrelevant/undefined
  if (options$anneal_length != 0){
    output$T_decay = -log10(1e-6)/options$anneal_length
  } else {
    # if anneal length is 0, then set T_decay to none 
    # so that we get error if we ever try to use it
    output$T_decay = NULL
  }
  
  
  #### this part is not ok but it doesn't influence the example because there is no seed given
  if (!is.null(options$seed)){
      set.seed(options$seed)
      output$random = runif(1)
  } else {
      output$random = runif(1)
  }
  #########
  
  
  output$start_iter = 0
  output$acceptance = 0
  output$T = options$T_init
  output$sig_value = 1
  output$hessian = NULL
  
  output$delta_posteriors = numeric(options$nsteps)
  output$ts = numeric(options$nsteps)
  output$priors = numeric(options$nsteps)
  output$likelihoods = numeric(options$nsteps)
  output$posteriors = numeric(options$nsteps)
  output$positions = matrix(0,options$nsteps, output$num_estimate)
  output$alphas = numeric(options$nsteps)
  output$sigmas = numeric(options$nsteps)
  output$accepts = logical(options$nsteps)
  output$rejects = logical(options$nsteps)
  hessian_steps = options$nsteps - options$anneal_length
  num_hessians = ceiling(hessian_steps/options$hessian_period)
  
  # initialize to zeros so we can see where there were failures
  output$hessians = array(0, c(num_hessians, output$num_estimate, output$num_estimate))
  return(output)
}