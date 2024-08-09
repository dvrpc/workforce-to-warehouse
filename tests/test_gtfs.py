import unittest

from pygtfs import overwrite_feed
from pygtfs import Schedule

from sqlalchemy.orm import Query
from dotenv import dotenv_values
config = dotenv_values("../.env")

class TestFeed(unittest.TestCase):

    def setUp(self):
        self.schedule = Schedule(config.get("DB_URI"))

    def test_feed_notnull(self):
        self.assertTrue(len(self.schedule.routes) > 0)
        
        

if __name__ == '__main__':
    unittest.main()
    
