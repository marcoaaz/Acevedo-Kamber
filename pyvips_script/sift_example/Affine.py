# -*- coding: utf-8 -*-
"""
Created on Tue May 31 10:16:07 2022

@author: n10832084
"""

############## Affine.py:
import numpy as np

def estimate_affine(s, t):
    num = s.shape[1]
    M = np.zeros((2 * num, 6))
    for i in range(num):
        temp = [[s[0, i], s[1, i], 0, 0, 1, 0], [0, 0, s[0, i], s[1, i], 0, 1]]
        M[2 * i: 2 * i + 2, :] = np.array(temp)
    b = t.T.reshape((2 * num, 1))
    theta = np.linalg.lstsq(M, b)[0]
    X = theta[:4].reshape((2, 2))
    Y = theta[4:]
    return X, Y