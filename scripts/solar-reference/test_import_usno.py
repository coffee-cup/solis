import unittest
from import_usno import DEST, parse_table

class TableTests(unittest.TestCase):
    def test_duplicate_rows_preserve_both_events(self):
        rows = parse_table((DEST/'raw/Toronto-2026-0.html').read_text(),2026)
        sunsets = [pair[1] for pair in rows[(8,29)] if pair[1].isdigit()]
        self.assertEqual(sunsets,['0000','2358'])

    def test_polar_states_and_single_crossings_are_distinct(self):
        rows = parse_table((DEST/'raw/North_Pole-2026-0.html').read_text(),2026)
        self.assertIn(['****','****'],rows[(6,15)])
        self.assertIn(['----','----'],rows[(12,15)])
        self.assertTrue(any(pair[0].isdigit() and not pair[1].strip() for pair in rows[(3,18)]))

    def test_rejects_missing_and_truncated_tables(self):
        for raw in ['<html>unavailable</html>', '<pre>2026\n01  1234 5678</pre>']:
            with self.assertRaises(ValueError):parse_table(raw,2026)

if __name__=='__main__':unittest.main()
