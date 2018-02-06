# Automatic Over the Air Deployment of Improved Machine Learning Models to IoT Devices for Edge Processing
Ricky Kirkendall

## Overview

For IoT devices, processing signals on the same layer that they are collected on is desirable because it lessens network dependency and output latency. Achieving this effect with deterministic types of processing is fairly straightforward, as it is simply a matter of running the formerly network-accessible program on the local hardware.

For non-deterministic types of programs, such as those enabled by modern machine learning techniques, there are a few more considerations. Requisite to these techniques is a training process that is both data heavy and compute intensive. This is a significant constraint to consider because most IoT hardware is purpose built for collecting and relaying signals, and, therefore, woefully ill-equipped to handle the intensive training process by which these systems "learn". Once trained, however, such programs shed their dependency on high-end hardware and run perfectly well on minimally equipped systems.

Without on-board training capabilities, these programs can be deployed to process data, but they have no hope improving their output by learning about their inputs.

The system proposed in this document aims to solve this problem by introducing a data-input, model-output feedback loop between the edge and cloud layers. The system uses networked, GPU-enabled machines to perform model training in the cloud as new data becomes available and pushes markedly improved models downstream to edge devices efficiently using delta-compression. In effect, this system can use data collection at the edge to build up the volume of data necessary to train a useful model as benchmarked by a given threshold. Once a given performance milestone is reached, either by improvements to the model architecture, or, from newly available training data, the updated model is sent to edge devices so that all future processing can occur at that layer.

An ideal use case for this system would be to build an unsupervised anomaly detection system that could live on-board edge devices. In this use case, the device would initially send all data up the cloud to build a training set. As the dataset grows, models will be trained at regular intervals until a target performance metric crosses a set threshold. An example would be the implementation of an anomaly detection module by use of a k-means clustering algorithm. In this example, an internal evaluation metric, such as the Silhouette coefficient, would be used as the target performance metric. Once the fully trained model is in place on-board the edge device, no further network usage will be necessary to detect signal anomalies.

## Proof of Concept Implementation

[Video](https://youtu.be/OCqB4B2tFFA)

![Demo GIF](https://media.giphy.com/media/xULW8jOIlWzxKxFbW0/giphy.gif)

In this demo, a convolutional neural network (CNN) trained on the MNIST dataset is embedded within an iOS application using the native CoreML framework. The model is controlled by a _custom SDK_ that is capable of "hot swapping" the existing model for an updated one without requiring any other changes to the host apps binary (which would require Apple App Store approval).

The initial version of the CNN model is handicapped because it was only trained on 10% of the data, and, thus, is not adequately performant.

The model's performance receives a big boost when 60% more training data becomes available. Once the new data is detected by the system's _custom continuous delivery system_, the model is retrained, tested and, if found to be sufficiently performant, exported according to a configuration file. The new exported model is statically hosted and a message is sent to the SDK to pull down the latest model and swap it out.
