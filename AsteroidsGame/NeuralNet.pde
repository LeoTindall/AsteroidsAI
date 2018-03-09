class NeuralNet {

  int iNodes;//No. of input nodes
  int[] hLayers; //Hidden layer descriptors
  int nHidden;//No. of hidden layers
  int oNodes;//No. of output nodes

  Matrix whi;//matrix containing weights between the input nodes and the hidden nodes
  ArrayList<Matrix> whh;//matrix containing weights between the hidden nodes
  Matrix woh;//matrix containing weights between the final hidden layer nodes and the output nodes


  //constructor
  NeuralNet(int inputs, int[] hiddenLayers, int outputNo) {
    
    if (hiddenLayers.length == 0) {
      throw new Error("Network must have at least one hidden layer or it is linearly seperable!");
    }

    //set dimensions from parameters
    hLayers = hiddenLayers;
    nHidden = hiddenLayers.length;
    iNodes = inputs;
    oNodes = outputNo;
    
    //create first layer weights 
    //included bias weight
    whi = new Matrix(hiddenLayers[0], iNodes + 1);

    //create hidden layer weights
    whh = new ArrayList<Matrix>();
    for (int hLayer = 0; hLayer < nHidden - 1; hLayer++) {
      // Add each set of weights, including bias
      whh.add(new Matrix(hiddenLayers[hLayer + 1], hiddenLayers[hLayer] +1));
    }

    //create weights between output and last hidden layer
    //include bias weight
    woh = new Matrix(oNodes, hiddenLayers[nHidden - 1]);  

    //set the matricies to random values
    whi.randomize();
    for (int hLayerW = 0; hLayerW < whh.size(); hLayerW++) {
      whh.get(hLayerW).randomize();
    }
    woh.randomize();
  }


  //mutation function for genetic algorithm
  void mutate(float mr) {
    //mutates each weight matrix
    whi.mutate(mr);
    for (int hLayerW = 0; hLayerW < whh.size(); hLayerW++) {
      whh.get(hLayerW).mutate(mr);
    }
    woh.mutate(mr);
  }


  //calculate the output values by feeding forward through the neural network
  float[] output(float[] inputsArr) {

    //convert array to matrix
    //Note woh has nothing to do with it its just a funciton in the Matrix class
    Matrix inputs = woh.singleColumnMatrixFromArray(inputsArr);

    //add bias 
    Matrix inputsBias = inputs.addBias();


    //-----------------------calculate the guessed output
    // Get the initial hidden inputs
    Matrix currentHiddenInputs;
    Matrix currentHiddenOutputs = whi.dot(inputsBias).activate();

    for (int hLayerW = 0; hLayerW < whh.size(); hLayerW++) {
      // Add bias and dot with next layer
      currentHiddenInputs = whh.get(hLayerW).dot(currentHiddenOutputs.addBias());
      // Activate based on previous layer's outputs
      currentHiddenOutputs = currentHiddenInputs.activate();
    }

    //apply final weights
    Matrix outputInputs = woh.dot(currentHiddenOutputs);
    //pass through activation function(sigmoid)
    Matrix outputs = outputInputs.activate();

    //convert to an array and return
    return outputs.toArray();
  }

  //crossover funciton for genetic algorithm
  NeuralNet crossover(NeuralNet partner) {

    //creates a new child with layer matricies from both parents
    NeuralNet child = new NeuralNet(iNodes, hLayers, oNodes);
    child.whi = whi.crossover(partner.whi);
    for (int hLayerW = 0; hLayerW < whh.size(); hLayerW++) {
      whh.get(hLayerW).crossover(partner.whh.get(hLayerW));
    }
    child.woh = woh.crossover(partner.woh);
    return child;
  }

  //return a neural net whihc is a clone of this Neural net
  NeuralNet clone() {
    NeuralNet clone  = new NeuralNet(iNodes, hLayers, oNodes); 
    clone.whi = whi.clone();
    for (int hLayerW = 0; hLayerW < whh.size(); hLayerW++) {
      clone.whh.set(hLayerW, whh.get(hLayerW));
    }
    clone.woh = woh.clone();

    return clone;
  }
}