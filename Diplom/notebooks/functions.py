from scipy.optimize import minimize
from sklearn.metrics import roc_curve, auc, roc_auc_score, confusion_matrix, classification_report, f1_score


def mtr(model, x, y, limit=0, metrics='AUC',
        meanclaim=66304, meanpremium=6946, meankv=0.18):
    '''
    Функция оптимизирует предсказания модели бинарной классификации по порогу принятия решения и 
    оценивает эффективность в  ROC-AUC (AUC) и в деньгах (money)
    '''
    pr = model.predict(x)
    if limit == 0:
        pred = pr
    elif limit == 1:
        def min(limit, model=model):
            s = model.predict_proba(x)
            r = []
            for i in s:
                if i[0] > limit:
                    r.append(0)
                else:
                    r.append(1)
            if metrics == 'AUC':
                res = roc_auc_score(y, r)
            elif metrics == 'money':
                cm = confusion_matrix(y, r)
                res = (cm[0][0] + cm[1][0]) * meanpremium * (1 - meankv) - cm[1][0] * meanclaim

            return -res

        l = minimize(min, 0.5, method='COBYLA')['x']
        print('Оптимальный лимит: ', l)
        print('')
        s = model.predict_proba(x)
        pred = []
        for i in s:
            if i[0] > l:
                pred.append(0)
            else:
                pred.append(1)

    else:
        s = model.predict_proba(x)
        pred = []
        for i in s:
            if i[0] > limit:
                pred.append(0)
            else:
                pred.append(1)
    cmf = confusion_matrix(y, pred)
    totalnewinput = round((cmf[0][0] + cmf[1][0]) * meanpremium * (1 - meankv) - cmf[1][0] * meanclaim, 0)
    print('Всего доход у нового метода: ', '{0:,}'.format(totalnewinput).replace(',', ' '))
    totalrealinput = round(len(y) * meanpremium * (1 - meankv) - sum(cmf[1]) * meanclaim, 0)
    print('Всего доход у текущего метода: ', '{0:,}'.format(totalrealinput).replace(',', ' '))
    upgrade = 100 - (totalrealinput / totalnewinput) * 100
    print('Доход больше, чем у текущего метода на ', round(upgrade, 2), '%')

    print('')
    print(cmf)
    print('')
    print(classification_report(y, pred))
    print('')
    print('ROC-AUC score: ', roc_auc_score(y, pred))