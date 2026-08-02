import pandas as pd
import numpy as np

class DataQualityChecker:
    """
    Class to automate data quality checks and profiling for logistics datasets.
    """
    def __init__(self, df: pd.DataFrame):
        self.df = df

    def check_duplicates(self) -> int:
        """Returns the number of duplicate rows."""
        return self.df.duplicated().sum()

    def check_missing_values(self) -> pd.DataFrame:
        """Returns summary of missing values per column."""
        missing = self.df.isnull().sum()
        missing_pct = (missing / len(self.df)) * 100
        result = pd.DataFrame({
            'missing_count': missing,
            'missing_pct': missing_pct
        })
        return result[result['missing_count'] > 0].sort_values(by='missing_count', ascending=False)

    def detect_shipping_anomalies(self) -> pd.DataFrame:
        """
        Detects logic anomalies where late delivery risk is 0 
        but real shipping days strictly exceed scheduled days.
        """
        condition = (self.df['Days for shipping (real)'] > self.df['Days for shipment (scheduled)']) & \
                    (self.df['Late_delivery_risk'] == 0)
        return self.df[condition]

    def generate_health_report(self) -> dict:
        """Generates a quick dictionary health score of the dataset."""
        total_rows = len(self.df)
        duplicates = self.check_duplicates()
        anomalies = len(self.detect_shipping_anomalies())
        
        health_score = max(0, 100 - ((duplicates + anomalies) / total_rows * 100))
        
        return {
            'total_records': total_rows,
            'duplicate_rows': duplicates,
            'shipping_anomalies': anomalies,
            'data_health_score_pct': round(health_score, 2)
        }