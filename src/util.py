import cv2
from mediapipe import solutions
from mediapipe.framework.formats import landmark_pb2
import numpy as np
import math

MARGIN = 10  # pixels
FONT_SIZE = 1
FONT_THICKNESS = 1
HANDEDNESS_TEXT_COLOR = (88, 205, 54) # vibrant green

def draw_landmarks_on_image(rgb_image, detection_result):
  hand_landmarks_list = detection_result.hand_landmarks
  handedness_list = detection_result.handedness
  annotated_image = np.copy(rgb_image)

  # Loop through the detected hands to visualize.
  for idx in range(len(hand_landmarks_list)):
    hand_landmarks = hand_landmarks_list[idx]
    handedness = handedness_list[idx]

    # Draw the hand landmarks.
    hand_landmarks_proto = landmark_pb2.NormalizedLandmarkList()
    hand_landmarks_proto.landmark.extend([
      landmark_pb2.NormalizedLandmark(x=landmark.x, y=landmark.y, z=landmark.z) for landmark in hand_landmarks
    ])
    solutions.drawing_utils.draw_landmarks(
      annotated_image,
      hand_landmarks_proto,
      solutions.hands.HAND_CONNECTIONS,
      solutions.drawing_styles.get_default_hand_landmarks_style(),
      solutions.drawing_styles.get_default_hand_connections_style()
      )

    # Get the top left corner of the detected hand's bounding box.
    height, width, _ = annotated_image.shape
    x_coordinates = [landmark.x for landmark in hand_landmarks]
    y_coordinates = [landmark.y for landmark in hand_landmarks]
    text_x = int(min(x_coordinates) * width)
    text_y = int(min(y_coordinates) * height) - MARGIN

    # Draw handedness (left or right hand) on the image.
    cv2.putText(annotated_image, f"{handedness[0].category_name}",
                (text_x, text_y), cv2.FONT_HERSHEY_DUPLEX,
                FONT_SIZE, HANDEDNESS_TEXT_COLOR, FONT_THICKNESS, cv2.LINE_AA)

  return annotated_image


def calc_landmarks_coord(result, img):
    height, width, _ = img.shape
    landmarks_coord = []
    
    if result.hand_landmarks:
        for i in range(len(result.hand_landmarks)):
          landmarks_list = result.hand_landmarks[i]
        #   if (i == 2) and (result.handedness[0][i].category_name == 'Right'):
        #      landmarks_list = landmarks_list.reverse()
          landmarks_coord.append([])
          for _, landmark in enumerate(landmarks_list):
              landmark_x = int(np.floor(landmark.x * width))
              landmark_y = int(np.floor(landmark.y * height))
              landmarks_coord[i].append([landmark_x, landmark_y])
    return landmarks_coord

def calc_center_of_gravity(coord_list):
  if coord_list: 
    coord_array = np.array(coord_list)
    x = coord_array[:,0]
    y = coord_array[:,1]
    center_x = int(np.mean(x))
    center_y = int(np.mean(y))
    center = [center_x, center_y]
    return center
  else:
     return []



LINE_THICKNESS = 1


## DEBUGGING
# def drawing_landmarks(result, img):
#   hand_landmarks_coord = calc_landmarks_coord(result, img)
#   print(len(hand_landmarks_coord))
#   return img

def drawing_landmarks(result, img):
  center_of_gravity = []
  both_hands_landmarks_coord = calc_landmarks_coord(result, img)
  for i in range(len(both_hands_landmarks_coord)):
    hand_landmarks_coord = both_hands_landmarks_coord[i]
    center_of_gravity = calc_center_of_gravity(hand_landmarks_coord)
    # print(center_of_gravity)
    if len(hand_landmarks_coord)>0:
      
      # THUMB
      cv2.line(img, 
              tuple(hand_landmarks_coord[2]),
              tuple(hand_landmarks_coord[3]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[3]),
              tuple(hand_landmarks_coord[4]),
              (255,255,255),
              LINE_THICKNESS)
      
      # INDEX
      cv2.line(img, 
              tuple(hand_landmarks_coord[5]),
              tuple(hand_landmarks_coord[6]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[6]),
              tuple(hand_landmarks_coord[7]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[7]),
              tuple(hand_landmarks_coord[8]),
              (255,255,255),
              LINE_THICKNESS)
      
      # MIDDLE
      cv2.line(img, 
              tuple(hand_landmarks_coord[9]),
              tuple(hand_landmarks_coord[10]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[10]),
              tuple(hand_landmarks_coord[11]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[11]),
              tuple(hand_landmarks_coord[12]),
              (255,255,255),
              LINE_THICKNESS)
      
      # RING
      cv2.line(img, 
              tuple(hand_landmarks_coord[13]),
              tuple(hand_landmarks_coord[14]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[14]),
              tuple(hand_landmarks_coord[15]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[15]),
              tuple(hand_landmarks_coord[16]),
              (255,255,255),
              LINE_THICKNESS)
      
      # PINKY
      cv2.line(img, 
              tuple(hand_landmarks_coord[17]),
              tuple(hand_landmarks_coord[18]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[18]),
              tuple(hand_landmarks_coord[19]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[19]),
              tuple(hand_landmarks_coord[20]),
              (255,255,255),
              LINE_THICKNESS)
      
      # PALM
      cv2.line(img, 
              tuple(hand_landmarks_coord[0]),
              tuple(hand_landmarks_coord[1]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[1]),
              tuple(hand_landmarks_coord[2]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[1]),
              tuple(hand_landmarks_coord[5]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[5]),
              tuple(hand_landmarks_coord[9]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[5]),
              tuple(hand_landmarks_coord[9]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[9]),
              tuple(hand_landmarks_coord[13]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[13]),
              tuple(hand_landmarks_coord[17]),
              (255,255,255),
              LINE_THICKNESS)
      cv2.line(img, 
              tuple(hand_landmarks_coord[17]),
              tuple(hand_landmarks_coord[0]),
              (255,255,255),
              LINE_THICKNESS)
      
      cv2.circle(img,
                tuple(center_of_gravity),
                3,
                (255,0,0),
                6)
      
      for i in range(len(hand_landmarks_coord)):
         if i%4 == 0:
            cv2.circle(img,
                   tuple(hand_landmarks_coord[i]),
                   3,
                   (20,20,20),
                   4)
         else:
            cv2.circle(img,
                   tuple(hand_landmarks_coord[i]),
                   3,
                   (100,100,100),
                   2)
            
      

    
  return img, center_of_gravity


THUMB_FINGER_INDEX = 4
INDEX_FINGER_INDEX = 8
def compute_Thumb2Index_Distance(both_hands_coord):
   if both_hands_coord:
        distance=[]
        for i in range(len(both_hands_coord)):
                distance.append([])
                coord = both_hands_coord[i]
                thumb_coord = coord[THUMB_FINGER_INDEX]
                index_coord = coord[INDEX_FINGER_INDEX]
                # print("thumb: {}".format(thumb_coord))
                # print("index: {}".format(index_coord))

                distance[i] = math.dist(thumb_coord, index_coord)

                # cv2.line(img, 
                #          tuple(thumb_coord),
                #          tuple(index_coord),
                #          (0,0,255),
                #          3)
        return distance



   


