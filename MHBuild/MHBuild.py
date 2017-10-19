import yaml
import coremltools
from keras.models import load_model
import os

def load_keras_model(file):
    print("-- MHBuild: Loading Keras Model...")
    model = load_model(file)
    return model

def save_keras_coreml(keras_model, model_name):
    print("-- MHBuild: Converting Keras model to CoreML model...")
    coreml_model = coremltools.converters.keras.convert(keras_model)
    fname = '{}.{}'.format(model_name,'mlmodel')
    fpath = 'output/{}'.format(fname)
    coreml_model.save(fpath)

def save_metadata(metadata_fname, thresh):
    #todo: open metadata file, write thresh to it, save it, close it
    metadata_fpath = 'output/{}'.format(metadata_fname)

    data = {}

    with open(metadata_fpath, 'r') as stream:
        y = yaml.load(stream)
        data['rating'] = y['rating']
        data['thresh'] = thresh

    with open(metadata_fpath, 'w') as stream:
        yaml.dump(data, stream, default_flow_style=False)

def execute_build_process(build_steps_arr):
    # NOTE: All file paths specified in the keras_cnn.py file are set relative to this directory. That will need to be fixed.
    print("-- MHBuild: Executing build process...")
    for step in build_steps_arr:
        print step
        os.system(step)


def parse(stream):
    print("-- MHBuild: Parsing mhbuild.yml...")
    data = yaml.load(stream)
    keras_model_fname = data['model-output-file']
    keras_model_name = data['model-name']
    metadata_fname = data['model-metadata-file']

    accuracy_threshold = data['deploy-threshold']

    build_steps = data['build-process']
    execute_build_process(build_steps)

    keras_model_fpath = 'output/{}'.format(keras_model_fname)
    kmodel = load_keras_model(keras_model_fpath)
    save_keras_coreml(kmodel, keras_model_name)

    save_metadata(metadata_fname, accuracy_threshold)

    

with open("mhbuild.yml", 'r') as stream:
    try:        
        parse(stream)
        
    except yaml.YAMLError as exc:
        print(exc)

