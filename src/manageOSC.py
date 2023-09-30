import argparse
import time
from pythonosc import udp_client
from util import *

flag_ROT = True
flag_PAN = True
flag_ZOOM = True

# ZOOM counter
zoom_count = 0

parser = argparse.ArgumentParser()

parser.add_argument("--ip", default="127.0.0.1",
                    help="the IP address of the listening machine, default=local")
parser.add_argument("--port", default = 12000, 
                    help="the port from which the server is listening, default=Processing port")
args = parser.parse_args()

client = udp_client.SimpleUDPClient(args.ip, args.port)

def sendHandCOG(COG_coord, width, height):
    if COG_coord:
        x = float(COG_coord[0])/width
        y = float(COG_coord[1])/height

        client.send_message("/hand_center_of_gravity", [x,y])

def send_TI_Near(both_hand_coord, hand, width, height):
    global flag_ROT
    global flag_ZOOM
    global flag_PAN
    global zoom_count
    if both_hand_coord:
        dist = compute_Thumb2Index_Distance(both_hand_coord)
        # ROTATION
        if len(dist) == 1 and dist[0] < 30 and hand[0][0].category_name == 'Right':
            coords = both_hand_coord[0]
            thumb_coord = coords[4]
            index_coord = coords[8]
            center_x = np.mean([thumb_coord[0], index_coord[0]])/width
            center_y = np.mean([thumb_coord[1], index_coord[1]])/height
            if flag_ROT:
                client.send_message("/PSS_rotation_start", [center_x, center_y])
                flag_ROT = False
            else:
                check_and_send_message("/PSS_rotation", [center_x, center_y])
        
            flag_ZOOM = True

        # PAN
        elif len(dist) == 1 and dist[0] < 30 and hand[0][0].category_name == 'Left':
            coords = both_hand_coord[0]
            thumb_coord = coords[4]
            index_coord = coords[8]
            center_x = np.mean([thumb_coord[0], index_coord[0]])/width
            center_y = np.mean([thumb_coord[1], index_coord[1]])/height
            if flag_PAN:
                client.send_message("/PSS_pan_start", [center_x, center_y])
                flag_PAN = False
            else:
                check_and_send_message("/PSS_pan", [center_x, center_y])
        
            flag_ZOOM = True

        # ZOOM
        elif len(dist) == 2 and dist[0] < 30 and dist[1] < 30:
            coords_r = both_hand_coord[0]
            coords_l = both_hand_coord[1]
            thumb_coord_r = coords_r[4]
            thumb_coord_l = coords_l[4]
            index_coord_r = coords_r[8]
            index_coord_l = coords_l[8]

            center_x_r = np.mean([thumb_coord_r[0], index_coord_r[0]])/width
            center_x_l = np.mean([thumb_coord_l[0], index_coord_l[0]])/width
        
            center_x = abs(center_x_r - center_x_l)
            if flag_ZOOM:
                client.send_message("/PSS_zoom_start", [center_x])
                flag_ZOOM = False
            else:
                if zoom_count == 5:
                    client.send_message("/PSS_zoom", [center_x])
                    zoom_count = 0
                else:
                    zoom_count = zoom_count + 1

            flag_ROT = True
            flag_PAN = True

        else:
            flag_ROT = True
            flag_PAN = True
            flag_ZOOM = True
            

        



def send_Mixer_Change(both_hand_coord, gest, hand, height): 
    
    if len(both_hand_coord) == 2:
        dist = compute_Thumb2Index_Distance(both_hand_coord)
        if ((dist[0] <= 30 and dist[1] > 30) or (dist[1] <= 30 and dist[0] > 30)):
            if hand[0][0].category_name == 'Right':
                if gest[0][0].category_name == 'One':
                    
                    if dist[1] < 30:
                        coords = both_hand_coord[1]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_1_changing", [center_y])
                if gest[0][0].category_name == 'Two':
                    if dist[1] < 30:
                        coords = both_hand_coord[1]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_2_changing", [center_y])
                if gest[0][0].category_name == 'Three':
                    if dist[1] < 30:
                        coords = both_hand_coord[1]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_3_changing", [center_y])
                if gest[0][0].category_name == 'Four':
                    if dist[1] < 30:
                        coords = both_hand_coord[1]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_4_changing", [center_y])        
            elif hand[1][0].category_name == 'Right':
                if gest[1][0].category_name == 'One':
                    if dist[0] < 30:
                        coords = both_hand_coord[0]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_1_changing", [center_y])
                if gest[1][0].category_name == 'Two':
                    if dist[0] < 30:
                        coords = both_hand_coord[0]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_2_changing", [center_y])
                if gest[1][0].category_name == 'Three':
                    if dist[0] < 30:
                        coords = both_hand_coord[0]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_3_changing", [center_y])
                if gest[1][0].category_name == 'Four':
                    if dist[0] < 30:
                        coords = both_hand_coord[0]
                        thumb_coord = coords[4]
                        index_coord = coords[8]
                        center_y = np.mean([thumb_coord[1], index_coord[1]])/height
                        check_and_send_message("/mixer_4_changing", [center_y])
        

def send_gesture(both_hand_coord, hand, gest):
    hand_msg = []
    if both_hand_coord:
        dist = compute_Thumb2Index_Distance(both_hand_coord)
        for i in range(len(both_hand_coord)):
            hand_msg.append(hand[i][0].category_name)
            if gest[i][0].category_name == "":
                if dist[i] < 30:
                    hand_msg[i]= hand_msg[i] + "Ok"
            else:
                if dist[i] < 30:
                    hand_msg[i]= hand_msg[i] + "Ok"
                else:
                    hand_msg[i] = hand_msg[i] + gest[i][0].category_name
        for i in range(len(hand_msg)):
            hand_msg[i] = code_msg(hand_msg[i])
        check_and_send_gesture("/gesture", hand_msg)
        
    else:
        check_and_send_gesture("/gesture", hand_msg)


def code_msg(str):
    match str:
        case "Left":
            str_mod = "L"
        case "Right":
            str_mod = "R"
        case "LeftOne":
            str_mod = "L1"
        case "RightOne":
            str_mod = "R1"
        case "LeftTwo":
            str_mod = "L2"
        case "RightTwo":
            str_mod = "R2"
        case "LeftThree":
            str_mod = "L3"
        case "RightThree":
            str_mod = "R3"
        case "LeftFour":
            str_mod = "L4"
        case "RightFour":
            str_mod = "R4"
        case "LeftOk":
            str_mod = "LO"
        case "RightOk":
            str_mod = "RO"            
    return str_mod 


def send_exit():
    client.send_message("/EXIT",[])


hystory = []
hystory_gesture = []
hystory_threshold=5

def check_and_send_message(name, args):
    if len(hystory)==0:
        hystory.append(name)
    elif name in hystory:
        hystory.append(name)
        if len(hystory) > hystory_threshold:
            client.send_message(name, args)
            hystory.pop()
    else:
        hystory.clear()
        hystory.append(name)
    

def check_and_send_gesture(name, args):
    if len(hystory_gesture)==0:
        hystory_gesture.append(args)
    elif args in hystory_gesture:
        hystory_gesture.append(args)
        if len(hystory_gesture) > hystory_threshold:
            client.send_message(name, args)
            hystory_gesture.pop()
    else:
        hystory_gesture.clear()
        hystory_gesture.append(args)
    



