import mediapipe as mp
import cv2
import os, glob
import subprocess
import threading
from util import *
from manageOSC import *
# from mediapipe.tasks import python
# from mediapipe.tasks.python import vision

# abs_path = os.path.dirname(os.path.abspath(__file__))
# model_path = os.path.join(abs_path, "./gesture_recognizer_CV.task")

# sc_path = "C:/Program Files/SuperCollider-3.12.2"
sc_path = glob.glob("C:/Program Files/SuperCollider*")[0]
# sc_path=sc_path[0]
print("SC PATH: "+sc_path)

print("ACTUAL PATH: "+os.getcwd())
dist_path = os.getcwd()

os.chdir('..')
abs_path = os.getcwd()

os.chdir(dist_path)

model_path = os.path.join(abs_path,"./gesture_recognizer_CV.task")

BaseOptions = mp.tasks.BaseOptions
GestureRecognizer = mp.tasks.vision.GestureRecognizer
GestureRecognizerOptions = mp.tasks.vision.GestureRecognizerOptions
GestureRecognizerResult = mp.tasks.vision.GestureRecognizerResult
VisionRunningMode = mp.tasks.vision.RunningMode

base_options = BaseOptions(model_asset_path=model_path)
img_to_draw = np.zeros((100,100,3), dtype=np.uint8)
cat=""

HEIGHT=0
WIDTH=0

flip_flag = True

def run_processing_sketch(sketch_path):
    global abs_path
    path = os.path.join(abs_path, "CelestialVibesPDE\\windows-amd64")

    os.chdir(path)
    os.system("CelestialVibesPDE.exe")

def run_supercollider(script_path):
    global sc_path
    sclang_path = os.path.join(sc_path,"sclang.exe")    
    os.system("taskkill /f /im sclang.exe")
    os.system("taskkill /f /im scsynth.exe")
    os.chdir(sc_path)
    subprocess.run([sclang_path, script_path])
    

if __name__ == "__main__":
    # Create a thread for running the Processing application
    current_directory = os.path.dirname(os.path.abspath(__file__))
    
    sketch_folder = os.path.join(abs_path, 'CelestialVibesPDE')
    script_sc_folder = os.path.join(abs_path, 'CelestialVibesPDE\CelestialVibesSC.scd')
   
    processing_thread = threading.Thread(target=run_processing_sketch, args=(sketch_folder,))
    processing_thread.start()
    
    supercollider_thread = threading.Thread(target=run_supercollider, args=(script_sc_folder,))
    supercollider_thread.daemon = True
    supercollider_thread.start()
    

# Create a gesture recognizer instance with the live stream mode:
def print_result(result: GestureRecognizerResult, output_image: mp.Image, timestamp_ms: int):
    gest = result.gestures
    handedness = result.handedness
    
    global cat
    global img_to_draw
    img = output_image.numpy_view()
    
    if gest:
        cat = gest[0][0].category_name
        
    else:
        cat="None"    
   
    landmarks_coord  = calc_landmarks_coord(result, img)
    img_to_draw, cog = drawing_landmarks(result, img)   

    distance = compute_Thumb2Index_Distance(landmarks_coord)

    send_TI_Near(landmarks_coord, handedness, WIDTH, HEIGHT)
    send_Mixer_Change(landmarks_coord, gest, handedness, HEIGHT)
    send_gesture(landmarks_coord, handedness, gest)
    

options = GestureRecognizerOptions(
    base_options = BaseOptions(model_asset_path=model_path),
    running_mode = VisionRunningMode.LIVE_STREAM,
    num_hands = 2,
    min_hand_detection_confidence = 0.2,
    min_hand_presence_confidence = 0.2,
    result_callback = print_result
    )

with GestureRecognizer.create_from_options(options) as recognizer:
    vid = cv2.VideoCapture(0)
    WIDTH = vid.get(cv2.CAP_PROP_FRAME_WIDTH)
    HEIGHT = vid.get(cv2.CAP_PROP_FRAME_HEIGHT)

    while True:
        # if "q" is pressed quit the program
        if cv2.waitKey(100)==ord('q'):
            send_exit()
            break

        # if keyboard.read_key()=="f":
        # if cv2.waitKey(5)==ord('f'):
        #     flip_flag = not(flip_flag)
        #     print(flip_flag)

        suc, frame = vid.read()
        if flip_flag:
            frame = cv2.flip(frame, 1)
        t = int(vid.get(cv2.CAP_PROP_POS_MSEC))

        if not suc:
            print("NO SUCCESS")
            break

        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame)

        recognizer.recognize_async(mp_image, t)

        cv2.putText(
                    img_to_draw, 
                    str(cat), 
                    (50,50), 
                    cv2.FONT_HERSHEY_COMPLEX,
                    1,
                    (0,0,0),
                    1
                    )
        
        cv2.line(img_to_draw, 
                 (int(WIDTH/2), 0),
                 (int(WIDTH/2), int(HEIGHT)),
                 (0,0,0),
                 1)
        cv2.line(img_to_draw, 
                 (0, int(HEIGHT/2)),
                 (int(WIDTH), int(HEIGHT/2)),
                 (0,0,0),
                 1)

        cv2.imshow("videoHand", img_to_draw)

    vid.release()
    cv2.destroyAllWindows()
    time.sleep(1)
    os.system("taskkill /f /im sclang.exe")
    os.system("taskkill /f /im scsynth.exe")




